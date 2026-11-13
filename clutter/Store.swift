import Foundation
import Observation

/// Everything clutter remembers between launches: which photos were reviewed,
/// which are waiting in the deletion inbox, and the one setting.
/// Stored as a small json file on the device.
@MainActor @Observable
final class Store {
    private(set) var reviewed: Set<String> = []
    private(set) var trash: [String] = []
    var skipAlbumed = false { didSet { scheduleSave() } }

    private struct Snapshot: Codable {
        var reviewed: Set<String>
        var trash: [String]
        var skipAlbumed: Bool
    }

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let url = URL.applicationSupportDirectory.appending(path: "state.json")

    init() {
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        reviewed = snapshot.reviewed
        trash = snapshot.trash
        skipAlbumed = snapshot.skipAlbumed
    }

    func keep(_ id: String) {
        trash.removeAll { $0 == id }
        reviewed.insert(id)
        scheduleSave()
    }

    func markForDeletion(_ id: String) {
        reviewed.remove(id)
        if !trash.contains(id) { trash.append(id) }
        scheduleSave()
    }

    /// Puts a photo back into the "not reviewed yet" state (undo).
    func forget(_ id: String) {
        reviewed.remove(id)
        trash.removeAll { $0 == id }
        scheduleSave()
    }

    /// Drops photos from the inbox once they are deleted or no longer exist.
    func removeFromTrash(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        trash.removeAll { ids.contains($0) }
        scheduleSave()
    }

    func startOver() {
        reviewed = []
        scheduleSave()
    }

    func save() {
        saveTask?.cancel()
        let snapshot = Snapshot(reviewed: reviewed, trash: trash, skipAlbumed: skipAlbumed)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { save() }
        }
    }
}
