@preconcurrency import Photos
import UIKit
import Observation

enum Scope: Hashable {
    case all
    case random
    case month(year: Int, month: Int)
}

struct MonthBucket: Identifiable, Hashable {
    let year: Int
    let month: Int
    let remaining: Int

    var id: Int { year * 100 + month }
    var scope: Scope { .month(year: year, month: month) }

    var title: String {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? .now
        return date.formatted(.dateTime.month(.wide).year()).lowercased()
    }
}

/// Thin wrapper around the system Photos library.
@MainActor @Observable
final class Library {
    private(set) var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    private(set) var months: [MonthBucket] = []
    private(set) var remaining = 0
    private(set) var albums: [PHAssetCollection] = []
    private(set) var loaded = false

    @ObservationIgnored private var albumed: Set<String> = []
    @ObservationIgnored private var reloads = 0
    @ObservationIgnored private var lastWrite: Task<Void, Never>?

    func requestAccess() async {
        status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: Reading

    private struct Scan {
        var months: [MonthBucket] = []
        var remaining = 0
        var albums: [PHAssetCollection] = []
        var albumed: Set<String> = []
        var missingTrash: Set<String> = []
    }

    /// Recounts what is left to review, per month and in total.
    func reload(store: Store) async {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized else { return }
        let trash = store.trash
        let excluded = store.reviewed.union(trash)
        let skipAlbumed = store.skipAlbumed
        reloads += 1
        let reload = reloads
        let scan = await Task.detached(priority: .userInitiated) {
            Self.scan(excluded: excluded, trash: trash, skipAlbumed: skipAlbumed)
        }.value
        // A newer reload started meanwhile: its result wins, this one is stale.
        guard reload == reloads else { return }
        months = scan.months
        remaining = scan.remaining
        albums = scan.albums
        albumed = scan.albumed
        loaded = true
        store.removeFromTrash(scan.missingTrash)
    }

    nonisolated private static func scan(excluded: Set<String>, trash: [String], skipAlbumed: Bool) -> Scan {
        var scan = Scan()

        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            .enumerateObjects { album, _, _ in
                if album.canPerform(.addContent) { scan.albums.append(album) }
                guard skipAlbumed else { return }
                PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in
                    scan.albumed.insert(asset.localIdentifier)
                }
            }

        var counts: [Int: Int] = [:]
        let calendar = Calendar.current
        PHAsset.fetchAssets(with: nil).enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            let left = !excluded.contains(id) && !scan.albumed.contains(id)
            if left { scan.remaining += 1 }
            guard let date = asset.creationDate else { return }
            let parts = calendar.dateComponents([.year, .month], from: date)
            guard let year = parts.year, let month = parts.month else { return }
            counts[year * 100 + month, default: 0] += left ? 1 : 0
        }
        scan.months = counts.keys.sorted(by: >).map {
            MonthBucket(year: $0 / 100, month: $0 % 100, remaining: counts[$0] ?? 0)
        }

        var found: Set<String> = []
        PHAsset.fetchAssets(withLocalIdentifiers: trash, options: nil).enumerateObjects { asset, _, _ in
            found.insert(asset.localIdentifier)
        }
        scan.missingTrash = Set(trash).subtracting(found)
        return scan
    }

    /// The photos still to review for a scope, oldest first (or shuffled for random).
    func queue(for scope: Scope, store: Store) async -> [PHAsset] {
        var excluded = store.reviewed.union(store.trash)
        if store.skipAlbumed { excluded.formUnion(albumed) }
        return await Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            if case let .month(year, month) = scope,
               let start = Calendar.current.date(from: DateComponents(year: year, month: month)),
               let end = Calendar.current.date(byAdding: .month, value: 1, to: start) {
                options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
            }
            var assets: [PHAsset] = []
            PHAsset.fetchAssets(with: options).enumerateObjects { asset, _, _ in
                if !excluded.contains(asset.localIdentifier) { assets.append(asset) }
            }
            return scope == .random ? assets.shuffled() : assets
        }.value
    }

    func assets(withIDs ids: [String]) -> [PHAsset] {
        var byID: [String: PHAsset] = [:]
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil).enumerateObjects { asset, _, _ in
            byID[asset.localIdentifier] = asset
        }
        return ids.compactMap { byID[$0] }
    }

    // MARK: Writing

    func createAlbum(named name: String) async -> PHAssetCollection? {
        var placeholderID: String?
        do {
            try await PHPhotoLibrary.shared().performChanges {
                placeholderID = PHAssetCollectionChangeRequest
                    .creationRequestForAssetCollection(withTitle: name)
                    .placeholderForCreatedAssetCollection.localIdentifier
            }
        } catch { return nil }
        guard let placeholderID,
              let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholderID], options: nil).firstObject
        else { return nil }
        albums.append(album)
        return album
    }

    func contains(_ asset: PHAsset, in album: PHAssetCollection) -> Bool {
        var found = false
        PHAssetCollection.fetchAssetCollectionsContaining(asset, with: .album, options: nil)
            .enumerateObjects { collection, _, stop in
                if collection.localIdentifier == album.localIdentifier {
                    found = true
                    stop.pointee = true
                }
            }
        return found
    }

    func add(_ asset: PHAsset, to albums: [PHAssetCollection]) {
        write {
            for album in albums {
                PHAssetCollectionChangeRequest(for: album)?.addAssets([asset] as NSArray)
            }
        }
    }

    func remove(_ asset: PHAsset, from albums: [PHAssetCollection]) {
        write {
            for album in albums {
                PHAssetCollectionChangeRequest(for: album)?.removeAssets([asset] as NSArray)
            }
        }
    }

    /// Album changes run one after another, in the order they were asked for,
    /// so an undo can never overtake the add it reverses.
    private func write(_ changes: @escaping @Sendable () -> Void) {
        let previous = lastWrite
        lastWrite = Task {
            await previous?.value
            try? await PHPhotoLibrary.shared().performChanges(changes)
        }
    }

    /// Asks the system to delete the photos. iOS shows its own confirmation;
    /// returns false if the user cancels it.
    func delete(ids: [String]) async -> Bool {
        // One item the system refuses to delete (e.g. synced from a computer)
        // would make the whole request fail, so those are left out.
        var assets: [PHAsset] = []
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil).enumerateObjects { asset, _, _ in
            if asset.canPerform(.delete) { assets.append(asset) }
        }
        guard !assets.isEmpty else { return true }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Asset helpers

extension PHAsset: @retroactive Identifiable {
    public var id: String { localIdentifier }
}

extension PHAsset {
    var kind: String {
        switch mediaType {
        case .video: return "video"
        case .audio: return "audio"
        default:
            if mediaSubtypes.contains(.photoLive) { return "live photo" }
            if mediaSubtypes.contains(.photoScreenshot) { return "screenshot" }
            return "photo"
        }
    }

    /// e.g. "video · 0:14 · 12 march 2025"
    var caption: String {
        var parts = [kind]
        if mediaType == .video {
            parts.append(Duration.seconds(duration.rounded()).formatted(.time(pattern: .minuteSecond)))
        }
        if let creationDate {
            parts.append(creationDate.formatted(date: .long, time: .omitted).lowercased())
        }
        return parts.joined(separator: " · ")
    }

    /// Delivers a quick low-quality image first, then the full-quality one.
    func images(targetSize: CGSize, contentMode: PHImageContentMode = .aspectFit) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            let request = PHImageManager.default().requestImage(
                for: self, targetSize: targetSize, contentMode: contentMode, options: options
            ) { image, info in
                if let image { continuation.yield(image) }
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !degraded { continuation.finish() }
            }
            continuation.onTermination = { _ in
                PHImageManager.default().cancelImageRequest(request)
            }
        }
    }
}
