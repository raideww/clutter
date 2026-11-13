import SwiftUI
import Photos

struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(Library.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var path: [Scope] = []
    @State private var showInbox = false
    @State private var confirmStartOver = false

    var body: some View {
        @Bindable var store = store

        NavigationStack(path: $path) {
            content
                .navigationTitle("clutter")
                .navigationDestination(for: Scope.self) { ReviewView(scope: $0) }
                .toolbar {
                    if library.status == .authorized {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu("options", systemImage: "ellipsis") {
                                Toggle("skip photos already in albums", systemImage: "rectangle.stack", isOn: $store.skipAlbumed)
                                Button("start over", systemImage: "arrow.counterclockwise", role: .destructive) {
                                    confirmStartOver = true
                                }
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $showInbox, onDismiss: reload) { InboxView() }
        .confirmationDialog(
            "forget which photos you already reviewed?",
            isPresented: $confirmStartOver,
            titleVisibility: .visible
        ) {
            Button("start over", role: .destructive) {
                store.startOver()
                reload()
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("every photo will show up again. photos waiting for deletion stay in the inbox.")
        }
        .task {
            if library.status == .notDetermined { await library.requestAccess() }
            await library.reload(store: store)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { reload() } else { store.save() }
        }
        .onChange(of: path) {
            if path.isEmpty { reload() }
        }
        .onChange(of: store.skipAlbumed) { reload() }
    }

    private func reload() {
        Task { await library.reload(store: store) }
    }

    @ViewBuilder
    private var content: some View {
        switch library.status {
        case .authorized:
            if !library.loaded {
                ProgressView()
            } else if library.months.isEmpty {
                ContentUnavailableView("no photos", systemImage: "photo.on.rectangle", description: Text("your photo library is empty."))
            } else {
                list
            }
        case .notDetermined:
            Color.clear
        default:
            ContentUnavailableView {
                Label("no access to photos", systemImage: "lock")
            } description: {
                Text("clutter needs full access to your photo library to organize it. choose \"full access\" in settings.")
            } actions: {
                Button("open settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.glassProminent)
            }
        }
    }

    private var list: some View {
        List {
            if !store.trash.isEmpty {
                Section {
                    Button { showInbox = true } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("^[\(store.trash.count) item](inflect: true) waiting for deletion")
                                    .foregroundStyle(.primary)
                                Text("review and delete")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "tray.full")
                        }
                    }
                }
            }

            Section {
                NavigationLink(value: Scope.all) {
                    row("all photos", symbol: "photo.on.rectangle", remaining: library.remaining)
                }
                NavigationLink(value: Scope.random) {
                    row("random", symbol: "shuffle", remaining: library.remaining)
                }
            }

            Section {
                ForEach(library.months) { month in
                    NavigationLink(value: month.scope) {
                        row(month.title, symbol: nil, remaining: month.remaining)
                    }
                }
            } header: {
                Text("months").textCase(nil)
            }
        }
    }

    private func row(_ title: String, symbol: String?, remaining: Int) -> some View {
        LabeledContent {
            if remaining == 0 {
                Image(systemName: "checkmark")
                    .accessibilityLabel("done")
            } else {
                Text(remaining, format: .number)
                    .monospacedDigit()
            }
        } label: {
            if let symbol {
                Label(title, systemImage: symbol)
            } else {
                Text(title)
            }
        }
    }
}
