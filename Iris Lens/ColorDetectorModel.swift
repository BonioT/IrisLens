//
//  ColorDetectorModel.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import AVFoundation
import SwiftUI
import Combine
import CoreImage
import Photos
import UIKit

class ColorDetectorModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var processedFrame: CGImage?
    
    @Published var selectedMode: VisionMode = .normal {
        didSet { reprocessIfNeeded() }
    }
    @Published var isGrayscaleEnabled: Bool = false {
        didSet { reprocessIfNeeded() }
    }
    @Published var isFrozen: Bool = false
    
    @Published var selectedColorName: String = "—"
    @Published var selectedColor: Color = .clear
    @Published var lastTapPoint: CGPoint?
    
    @Published var importedImage: UIImage? {
        didSet {
            if let uiImage = importedImage {
                isFrozen = true
                lastTapPoint = nil // Reset tap on new image
                processUIImage(uiImage)
            } else {
                isFrozen = false
            }
        }
    }
    
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.processing.queue")
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    
    private var cubeDataCache: [VisionMode: Data] = [:]
    private let cubeSize = 64
    
    // Zoom state
    @Published var zoomFactor: CGFloat = 1.0
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func reprocessIfNeeded() {
        if let img = importedImage {
            processUIImage(img)
        } else if isFrozen, let original = capturedOriginalCI {
            processCIImage(original)
        }
    }
    
    func setZoom(_ factor: CGFloat) {
        let zoom = max(1.0, min(factor, 5.0)) // Max 5x zoom
        zoomFactor = zoom
        
        if importedImage == nil && !isFrozen {
            // Live camera zoom
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            try? device.lockForConfiguration()
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
        }
    }
    
    func toggleFreeze() {
        isFrozen.toggle()
        lastTapPoint = nil
        selectedColorName = "—"
        selectedColor = .clear
        if !isFrozen {
            importedImage = nil
            setZoom(1.0) // Reset zoom when returning to live if frozen
        }
    }
    
    func clearImportedImage() {
        importedImage = nil
        isFrozen = false
        setZoom(1.0)
    }
    
    func saveCurrentFrameToPhotos() {
        guard let cg = processedFrame else { return }
        let image = UIImage(cgImage: cg)
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: nil)
        }
    }
    
    private func activeColorRanges(for mode: VisionMode) -> [TrackedColor] {
        switch mode {
        case .deuteranomaly: return [.green]
        case .protanomaly: return [.red]
        case .tritanomaly: return [.blue, .yellow]
        case .normal: return []
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupCamera() }
            }
        default: break
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = session.canSetSessionPreset(.hd1920x1080) ? .hd1920x1080 : .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(output) { session.addOutput(output) }
        
        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        session.commitConfiguration()
        queue.async { self.session.startRunning() }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if importedImage != nil { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if isFrozen { return }
        
        let original = CIImage(cvPixelBuffer: pixelBuffer)
        processCIImage(original)
    }
    
    private func processUIImage(_ uiImage: UIImage) {
        guard let ciImage = CIImage(image: uiImage) else { return }
        let fixedImage = ciImage.matchedBySettingOrientation(uiImage.imageOrientation)
        processCIImage(fixedImage)
    }
    
    private var capturedOriginalCI: CIImage?
    
    private func processCIImage(_ original: CIImage) {
        capturedOriginalCI = original
        let extent = original.extent
        sampleColor(from: original)
        
        let outputImage: CIImage
        if selectedMode == .normal {
            outputImage = original
        } else {
            let cubeData = getCubeData(for: selectedMode)
            let maskCI = original.applyingFilter("CIColorCube", parameters: ["inputCubeDimension": cubeSize, "inputCubeData": cubeData])
            
            var background = original
            if isGrayscaleEnabled {
                background = background.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.0])
            }
            background = background.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.30, // Darker
                kCIInputSaturationKey: isGrayscaleEnabled ? 0.0 : 0.50, // More muted
                kCIInputContrastKey: 1.1
            ])
            let blurredBackground = background.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 4.0]).cropped(to: extent) // More blur
            
            let boosted = original.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.15,
                kCIInputSaturationKey: 2.8, // Stronger saturation
                kCIInputContrastKey: 1.2
            ])
            
            outputImage = boosted.applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: blurredBackground,
                kCIInputMaskImageKey: maskCI
            ])
        }
        
        guard let outCG = ciContext.createCGImage(outputImage, from: extent) else { return }
        DispatchQueue.main.async { self.processedFrame = outCG }
    }
    
    func handleTap(at normalizedPoint: CGPoint) {
        lastTapPoint = normalizedPoint
        if isFrozen, let original = capturedOriginalCI {
            sampleColor(from: original)
        }
    }
    
    private func sampleColor(from image: CIImage) {
        let samplePoint: CGPoint
        
        if isFrozen {
            if let tap = lastTapPoint {
                // Map normalized tap (0-1) to image extent
                samplePoint = CGPoint(
                    x: image.extent.minX + tap.x * image.extent.width,
                    y: image.extent.minY + (1.0 - tap.y) * image.extent.height // Flip Y for CIImage
                )
            } else {
                // No tap yet in frozen mode
                DispatchQueue.main.async {
                    self.selectedColorName = "—"
                    self.selectedColor = .clear
                }
                return
            }
        } else {
            // Live center
            samplePoint = CGPoint(x: image.extent.midX, y: image.extent.midY)
        }
        
        // Sample a 5x5 area to reduce noise
        let sampleSize: CGFloat = 5
        let offset = (sampleSize - 1) / 2
        let rect = CGRect(x: samplePoint.x - offset, y: samplePoint.y - offset, width: sampleSize, height: sampleSize)
        
        var bitmap = [UInt8](repeating: 0, count: Int(4 * sampleSize * sampleSize))
        ciContext.render(image, toBitmap: &bitmap, rowBytes: Int(4 * sampleSize), bounds: rect, format: .RGBA8, colorSpace: nil)
        
        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0
        
        let pixelCount = sampleSize * sampleSize
        for i in 0..<Int(pixelCount) {
            totalR += Double(bitmap[i * 4])
            totalG += Double(bitmap[i * 4 + 1])
            totalB += Double(bitmap[i * 4 + 2])
        }
        
        let r = (totalR / pixelCount) / 255.0
        let g = (totalG / pixelCount) / 255.0
        let b = (totalB / pixelCount) / 255.0
        
        let colorName = ColorNamer.name(for: r, g: g, b: b)
        let colorValue = Color(red: r, green: g, blue: b)
        
        DispatchQueue.main.async {
            self.selectedColorName = colorName
            self.selectedColor = colorValue
        }
    }
    
    private func getCubeData(for mode: VisionMode) -> Data {
        if let cached = cubeDataCache[mode] { return cached }
        let data = createCubeData(for: mode)
        cubeDataCache[mode] = data
        return data
    }
    
    private func createCubeData(for mode: VisionMode) -> Data {
        let count = cubeSize * cubeSize * cubeSize
        var cubeData = [Float](repeating: 0, count: count * 4)
        let colors = activeColorRanges(for: mode)
        
        for b in 0..<cubeSize {
            let bf = Double(b) / Double(cubeSize - 1)
            for g in 0..<cubeSize {
                let gf = Double(g) / Double(cubeSize - 1)
                for r in 0..<cubeSize {
                    let rf = Double(r) / Double(cubeSize - 1)
                    let isMatch = matchesHSV(r: rf, g: gf, b: bf, against: colors)
                    let offset = ((b * cubeSize + g) * cubeSize + r) * 4
                    let alpha: Float = isMatch ? 1.0 : 0.0
                    cubeData[offset] = alpha
                    cubeData[offset+1] = alpha
                    cubeData[offset+2] = alpha
                    cubeData[offset+3] = alpha
                }
            }
        }
        return Data(bytes: cubeData, count: cubeData.count * 4)
    }
    
    private func matchesHSV(r: Double, g: Double, b: Double, against colors: [TrackedColor]) -> Bool {
        let (h, s, v) = rgbToHSV(r: r, g: g, b: b)
        let hueDeg = h * 360.0
        for color in colors {
            if s < color.minSaturation || v < color.minValue { continue }
            let range = color.hueRangeDegrees
            if range.min <= range.max {
                if hueDeg >= range.min && hueDeg <= range.max { return true }
            } else {
                if hueDeg >= range.min || hueDeg <= range.max { return true }
            }
        }
        return false
    }
    
    private func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        let delta = maxVal - minVal
        var h: Double = 0
        if delta != 0 {
            if maxVal == r { h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6)) }
            else if maxVal == g { h = 60 * (((b - r) / delta) + 2) }
            else { h = 60 * (((r - g) / delta) + 4) }
        }
        if h < 0 { h += 360 }
        return (h / 360.0, maxVal == 0 ? 0 : (delta / maxVal), maxVal)
    }
}

extension CIImage {
    func matchedBySettingOrientation(_ orientation: UIImage.Orientation) -> CIImage {
        switch orientation {
        case .up: return self
        case .down: return self.oriented(.down)
        case .left: return self.oriented(.left)
        case .right: return self.oriented(.right)
        case .upMirrored: return self.oriented(.upMirrored)
        case .downMirrored: return self.oriented(.downMirrored)
        case .leftMirrored: return self.oriented(.leftMirrored)
        case .rightMirrored: return self.oriented(.rightMirrored)
        @unknown default: return self
        }
    }
}
