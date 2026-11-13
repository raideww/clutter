import SwiftUI
import AVFoundation
@preconcurrency import Photos
import PhotosUI

/// Shows one library item: a photo, a live photo or a video.
/// Videos and live photos get a play button.
struct AssetView: View {
    let asset: PHAsset
    var isActive = true

    @State private var image: UIImage?
    @State private var player: AVPlayer?
    @State private var livePhoto: PHLivePhoto?
    @State private var playing = false
    @State private var loadingVideo = false
    @State private var failed = false

    private var isVideo: Bool { asset.mediaType == .video }
    private var isLive: Bool { asset.mediaSubtypes.contains(.photoLive) }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(asset.caption)
            } else if failed {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("could not load · \(asset.caption)")
            } else {
                ProgressView()
            }
            if let player {
                PlayerView(player: player)
            }
            if let livePhoto, playing {
                LivePhotoView(livePhoto: livePhoto) { playing = false }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if isActive && (isVideo || isLive) { playButton }
        }
        .task(id: asset.localIdentifier) {
            for await image in asset.images(targetSize: CGSize(width: 1600, height: 1600)) {
                self.image = image
            }
            failed = image == nil && !Task.isCancelled
        }
        .onChange(of: isActive) {
            if !isActive { stop() }
        }
        .onDisappear(perform: stop)
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)) { note in
            guard let player, note.object as? AVPlayerItem === player.currentItem else { return }
            player.seek(to: .zero)
            playing = false
        }
    }

    private var playButton: some View {
        Button(action: toggle) {
            Image(systemName: isLive ? "livephoto" : (playing ? "pause.fill" : "play.fill"))
                .frame(width: 30, height: 30) // with the button's padding: a 44pt target
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .padding(12)
        .accessibilityLabel(isLive ? "play live photo" : (playing ? "pause" : "play video"))
    }

    private func stop() {
        player?.pause()
        playing = false
    }

    private func toggle() {
        if isVideo { toggleVideo() } else { playLivePhoto() }
    }

    private func toggleVideo() {
        if let player {
            if playing { player.pause() } else { player.play() }
            playing.toggle()
            return
        }
        // While the video is still loading, a tap only changes whether it starts when ready.
        playing.toggle()
        guard !loadingVideo else { return }
        loadingVideo = true
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
            DispatchQueue.main.async {
                loadingVideo = false
                guard let item else { playing = false; return }
                let player = AVPlayer(playerItem: item)
                self.player = player
                if playing { player.play() }
            }
        }
    }

    private func playLivePhoto() {
        if livePhoto != nil { playing = true; return }
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestLivePhoto(
            for: asset, targetSize: CGSize(width: 1600, height: 1600), contentMode: .aspectFit, options: options
        ) { photo, _ in
            DispatchQueue.main.async {
                guard let photo else { return }
                livePhoto = photo
                playing = true
            }
        }
    }
}

private struct PlayerView: UIViewRepresentable {
    let player: AVPlayer

    final class LayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
    }

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.isUserInteractionEnabled = false
        let layer = view.layer as? AVPlayerLayer
        layer?.player = player
        layer?.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: LayerView, context: Context) {
        (view.layer as? AVPlayerLayer)?.player = player
    }
}

private struct LivePhotoView: UIViewRepresentable {
    let livePhoto: PHLivePhoto
    let onEnd: () -> Void

    final class Coordinator: NSObject, PHLivePhotoViewDelegate {
        let onEnd: () -> Void
        init(onEnd: @escaping () -> Void) { self.onEnd = onEnd }

        func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            onEnd()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onEnd: onEnd) }

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        view.livePhoto = livePhoto
        view.delegate = context.coordinator
        DispatchQueue.main.async { view.startPlayback(with: .full) }
        return view
    }

    func updateUIView(_ view: PHLivePhotoView, context: Context) {}
}

/// Square thumbnail for grids.
struct Thumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Color(.secondarySystemFill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .task(id: asset.localIdentifier) {
                for await image in asset.images(targetSize: CGSize(width: 360, height: 360), contentMode: .aspectFill) {
                    self.image = image
                }
            }
            .accessibilityElement()
            .accessibilityLabel(asset.caption)
            .accessibilityAddTraits(.isImage)
    }
}
