import SwiftUI
@preconcurrency import Photos

/// One photo at a time: swipe right or tap keep, swipe left or tap delete.
/// Tapping an album adds the photo to it and moves on, in one tap.
struct ReviewView: View {
    let scope: Scope

    @Environment(Store.self) private var store
    @Environment(Library.self) private var library
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var queue: [PHAsset]?
    @State private var index = 0
    @State private var history: [Step] = []
    @State private var offset: CGSize = .zero
    @State private var animating = false
    @State private var showInbox = false
    @State private var showNewAlbum = false
    @State private var newAlbumName = ""

    private enum Kind { case keep, delete }

    private struct Step {
        let kind: Kind
        let albums: [PHAssetCollection]
    }

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        Group {
            if let queue {
                if index < queue.count {
                    review(queue)
                } else {
                    done
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("deletion inbox", systemImage: "tray.full") { showInbox = true }
                    .badge(store.trash.count)
            }
        }
        .sheet(isPresented: $showInbox, onDismiss: { history.removeAll() }) { InboxView() }
        .alert("new album", isPresented: $showNewAlbum) {
            TextField("name", text: $newAlbumName)
            Button("create", action: createAlbum)
            Button("cancel", role: .cancel) {}
        }
        .task {
            if queue == nil { queue = await library.queue(for: scope, store: store) }
        }
    }

    private var title: String {
        guard let queue, index < queue.count else { return "" }
        return "\(index + 1) of \(queue.count)"
    }

    // MARK: Reviewing

    private func review(_ queue: [PHAsset]) -> some View {
        let current = queue[index]
        // The next photo sits under the current one so it is ready when the card flies away.
        let visible = Array(queue[index..<min(index + 2, queue.count)].reversed())

        return VStack(spacing: 12) {
            ZStack {
                ForEach(visible, id: \.localIdentifier) { asset in
                    card(asset, isTop: asset.localIdentifier == current.localIdentifier)
                }
            }
            .padding(.horizontal)

            Text(current.caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            albumPicker

            HStack(spacing: 12) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .disabled(history.isEmpty)
                .accessibilityLabel("undo")

                Button(role: .destructive) { commit(.delete) } label: {
                    actionLabel("delete", symbol: "trash")
                }
                .buttonStyle(.glass)

                Button { commit(.keep) } label: {
                    actionLabel("keep", symbol: "checkmark")
                }
                .buttonStyle(.glassProminent)
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    /// At accessibility text sizes the words no longer fit side by side,
    /// so the buttons show their symbols only (VoiceOver still reads the words).
    @ViewBuilder
    private func actionLabel(_ title: String, symbol: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            Label(title, systemImage: symbol).labelStyle(.iconOnly).frame(maxWidth: .infinity)
        } else {
            Label(title, systemImage: symbol).frame(maxWidth: .infinity)
        }
    }

    private func card(_ asset: PHAsset, isTop: Bool) -> some View {
        AssetView(asset: asset, isActive: isTop)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 24))
            .overlay(alignment: .top) {
                if isTop { swipeHint }
            }
            .offset(isTop ? offset : .zero)
            .rotationEffect(.degrees(isTop && !reduceMotion ? offset.width / 25 : 0))
            .allowsHitTesting(isTop)
            .accessibilityHidden(!isTop)
            .gesture(drag, isEnabled: isTop)
    }

    /// Says what letting go will do, with a word and a symbol (not color alone).
    @ViewBuilder
    private var swipeHint: some View {
        let strength = min(abs(offset.width) / swipeThreshold, 1)
        if strength > 0.15 {
            Label(offset.width > 0 ? "keep" : "delete", systemImage: offset.width > 0 ? "checkmark" : "trash")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect()
                .padding(16)
                .opacity(strength)
                .accessibilityHidden(true)
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard !animating else { return }
                offset = CGSize(width: value.translation.width, height: value.translation.height * 0.3)
            }
            .onEnded { value in
                guard !animating else { return }
                let width = value.translation.width
                let predicted = value.predictedEndTranslation.width
                if width > swipeThreshold || (width > 40 && predicted > 300) {
                    commit(.keep)
                } else if width < -swipeThreshold || (width < -40 && predicted < -300) {
                    commit(.delete)
                } else {
                    withAnimation(.snappy) { offset = .zero }
                }
            }
    }

    private var albumPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                // minHeight 30 plus the button's own padding gives a 44pt tap target.
                Button {
                    newAlbumName = ""
                    showNewAlbum = true
                } label: {
                    Label("new album", systemImage: "plus").frame(minHeight: 30)
                }
                ForEach(library.albums, id: \.localIdentifier) { album in
                    Button { commit(.keep, album: album) } label: {
                        Text(album.localizedTitle ?? "untitled").frame(minHeight: 30)
                    }
                    .accessibilityHint("adds to this album and shows the next photo")
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Actions

    private func commit(_ kind: Kind, album: PHAssetCollection? = nil) {
        guard !animating, let queue, index < queue.count else { return }
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) { perform(kind, album: album) }
            return
        }
        animating = true
        withAnimation(.easeIn(duration: 0.18)) {
            offset = CGSize(width: kind == .keep ? 600 : -600, height: offset.height)
        } completion: {
            perform(kind, album: album)
            offset = .zero
            animating = false
        }
    }

    private func perform(_ kind: Kind, album: PHAssetCollection?) {
        guard let queue, index < queue.count else { return }
        let asset = queue[index]
        var albums: [PHAssetCollection] = []
        switch kind {
        case .keep:
            // If it was already in the album, undo must not take it out again.
            if let album, !library.contains(asset, in: album) { albums = [album] }
            store.keep(asset.localIdentifier)
            if !albums.isEmpty { library.add(asset, to: albums) }
        case .delete:
            store.markForDeletion(asset.localIdentifier)
        }
        history.append(Step(kind: kind, albums: albums))
        offset = .zero
        index += 1
    }

    private func undo() {
        guard !animating, let queue, index > 0, let step = history.popLast() else { return }
        let asset = queue[index - 1]
        store.forget(asset.localIdentifier)
        if !step.albums.isEmpty { library.remove(asset, from: step.albums) }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy) {
            index -= 1
        }
    }

    private func createAlbum() {
        let name = newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task {
            if let album = await library.createAlbum(named: name) {
                commit(.keep, album: album)
            }
        }
    }

    // MARK: Finished

    private var done: some View {
        ContentUnavailableView {
            Label("no photos left", systemImage: "checkmark.circle")
        } description: {
            if store.trash.isEmpty {
                Text("everything here is organized.")
            } else {
                Text("^[\(store.trash.count) item](inflect: true) waiting for deletion.")
            }
        } actions: {
            if !store.trash.isEmpty {
                Button("review and delete") { showInbox = true }
                    .buttonStyle(.glassProminent)
            }
            Button("done") { dismiss() }
        }
    }
}
