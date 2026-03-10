//
//  ContentView.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var model = ColorDetectorModel()
    @State private var showInfo = false
    @State private var selectedPickerItem: PhotosPickerItem?
    
    // Zoom states for local image manipulation (frozen/gallery)
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            mainPreview
            
            if model.isFrozen || model.importedImage != nil {
                if let tap = model.lastTapPoint {
                    tapMarker(at: tap)
                }
            } else {
                reticleOverlay
            }
            
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        importButton
                        if model.importedImage != nil {
                            clearImageButton
                        }
                    }
                    Spacer()
                    infoButton
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
                
                if !model.selectedColorName.isEmpty && model.selectedColorName != "—" {
                    colorNameBadge
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    freezeButton
                    saveButton
                }
                .padding(.bottom, 20)
                
                controlPanel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoSheet()
        }
        .onChange(of: selectedPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    model.importedImage = uiImage
                    currentZoom = 1.0
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var mainPreview: some View {
        GeometryReader { geo in
            Group {
                if let frame = model.processedFrame {
                    Image(decorative: frame, scale: 1.0, orientation: .up)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(model.importedImage != nil || model.isFrozen ? currentZoom : 1.0)
                        .clipped()
                        .contentShape(Rectangle())
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    if model.importedImage != nil || model.isFrozen {
                                        currentZoom = lastZoom * value
                                    } else {
                                        model.setZoom(lastZoom * value)
                                    }
                                }
                                .onEnded { value in
                                    if model.importedImage != nil || model.isFrozen {
                                        lastZoom = currentZoom
                                    } else {
                                        lastZoom = model.zoomFactor
                                    }
                                }
                        )
                        .onTapGesture { location in
                            let x_view = location.x / geo.size.width
                            let y_view = location.y / geo.size.height
                            
                            let normalized: CGPoint
                            if model.importedImage != nil || model.isFrozen {
                                // Adjust for zoom (assuming zoom from center)
                                let dx = x_view - 0.5
                                let dy = y_view - 0.5
                                normalized = CGPoint(x: 0.5 + dx / currentZoom, y: 0.5 + dy / currentZoom)
                            } else {
                                normalized = CGPoint(x: x_view, y: y_view)
                            }
                            model.handleTap(at: normalized)
                        }
                } else {
                    Color.black.overlay(ProgressView().tint(.white))
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func tapMarker(at normalizedPoint: CGPoint) -> some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(model.selectedColor)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: 1))
            }
            .position(x: normalizedPoint.x * geo.size.width, y: normalizedPoint.y * geo.size.height)
            .shadow(color: .black.opacity(0.4), radius: 8)
        }
    }
    
    private var reticleOverlay: some View {
        ZStack {
            Capsule().fill(.white).frame(width: 2, height: 24)
            Capsule().fill(.white).frame(width: 24, height: 2)
            Circle().stroke(.white, lineWidth: 1.5).frame(width: 6, height: 6)
        }
        .shadow(color: .black.opacity(0.3), radius: 5)
    }
    
    private var colorNameBadge: some View {
        Text(model.selectedColorName)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.selectedColorName)
    }
    
    private var infoButton: some View {
        Button { showInfo = true } label: {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.9))
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private var clearImageButton: some View {
        Button(action: model.clearImportedImage) {
            HStack(spacing: 6) {
                Image(systemName: "camera.fill")
                Text("LIVE").font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.8))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4)
        }
    }
    
    private var freezeButton: some View {
        Button(action: model.toggleFreeze) {
            Image(systemName: model.isFrozen ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .opacity(model.importedImage != nil ? 0.3 : 1.0)
        .disabled(model.importedImage != nil)
    }
    
    private var importButton: some View {
        PhotosPicker(selection: $selectedPickerItem, matching: .images) {
            Image(systemName: "photo.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
    }
    
    private var saveButton: some View {
        Button(action: model.saveCurrentFrameToPhotos) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 16) {
            Picker("Vision Mode", selection: $model.selectedMode) {
                ForEach(VisionMode.allCases) { mode in
                    Text(mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(4)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                Label {
                    Text("Highlight Mode")
                        .font(.subheadline.bold())
                } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                }
                .foregroundStyle(.white)
                
                Spacer()
                
                Toggle("", isOn: $model.isGrayscaleEnabled)
                    .labelsHidden()
                    .tint(.white)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct InfoSheet: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(VisionMode.allCases) { mode in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(mode.symbol)
                                    .font(.title3.bold())
                                    .frame(width: 40, height: 40)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Circle())
                                
                                Text(mode.title)
                                    .font(.headline)
                            }
                            
                            Text(mode.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Vision Modes")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }
}
