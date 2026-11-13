import SwiftUI
@preconcurrency import Photos

/// Everything marked for deletion. Look through it, rescue some, then delete the rest.
struct InboxView: View {
    @Environment(Store.self) private var store
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var assets: [PHAsset] = []
    @State private var preview: PHAsset?
    @State private var deleting = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        NavigationStack {
            Group {
                if store.trash.isEmpty {
                    ContentUnavailableView(
                        "nothing to delete",
                        systemImage: "tray",
                        description: Text("photos you choose to delete will wait here.")
                    )
                } else {
                    grid
                }
            }
            .navigationTitle("deletion inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .sheet(item: $preview) { asset in
            PreviewView(asset: asset) { restore(asset) }
        }
        .task(id: store.trash) {
            assets = library.assets(withIDs: store.trash)
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(assets) { asset in
                    Button { preview = asset } label: {
                        Thumbnail(asset: asset)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("opens a preview where you can keep it")
                    .contextMenu {
                        Button("keep", systemImage: "arrow.uturn.backward") { restore(asset) }
                    }
                }
            }
            Text("tap a photo to look at it or keep it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive, action: deleteAll) {
                Label {
                    Text("delete ^[\(store.trash.count) item](inflect: true)")
                } icon: {
                    Image(systemName: "trash")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(deleting)
            .padding()
        }
    }

    private func restore(_ asset: PHAsset) {
        store.keep(asset.localIdentifier)
    }

    private func deleteAll() {
        let ids = store.trash
        deleting = true
        Task {
            if await library.delete(ids: ids) {
                store.removeFromTrash(Set(ids))
                dismiss()
            }
            deleting = false
        }
    }
}

private struct PreviewView: View {
    let asset: PHAsset
    let onKeep: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AssetView(asset: asset)
                .navigationTitle(asset.caption)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("close", systemImage: "xmark") { dismiss() }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        onKeep()
                        dismiss()
                    } label: {
                        Label("keep this one", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .padding()
                }
        }
    }
}
