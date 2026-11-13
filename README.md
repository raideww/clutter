# clutter

an iPhone app for going through your photo library one item at a time. made by raideteam.

clutter is free, has no ads, no purchases and no account, and works fully on the device.

## features

- see your photos and videos one at a time. videos and live photos play on the card.
- swipe right or tap keep to keep. swipe left or tap delete to send to the deletion inbox.
- tap an album to add the photo to it and move on. create a new album in place.
- undo the last step.
- go through all photos (oldest first), in random order, or one month at a time. each month shows how many items are left.
- reviewed photos are remembered between launches. start over resets that.
- option to skip photos that are already in albums.
- nothing is deleted until you open the deletion inbox, look through it, keep anything you want back and confirm. iOS then moves the items to recently deleted for 30 days.

## requirements

- iPhone with iOS 26 or later
- Xcode with the iOS 26 or later sdk
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## build

1. run `xcodegen generate` in the repository folder.
2. open `clutter.xcodeproj`.
3. set your own development team under signing & capabilities. you can also change `DEVELOPMENT_TEAM` in `project.yml` before generating, so it stays set.
4. pick an iPhone or simulator and run.

the app asks for full photo library access on first launch. it needs full access to read and change albums.

## project layout

- `clutter/ClutterApp.swift`: app entry point
- `clutter/HomeView.swift`: home screen with all photos, random and months
- `clutter/ReviewView.swift`: one-at-a-time review with swipe, albums and undo
- `clutter/InboxView.swift`: deletion inbox
- `clutter/AssetView.swift`: photo, video and live photo display
- `clutter/Library.swift`: reading and changing the photo library
- `clutter/Store.swift`: local state saved as a small json file

## privacy

clutter collects no data. it has no server, no analytics and no ads. photos are read and changed only on the device. see [PRIVACY.md](PRIVACY.md).

## license

MIT. see the LICENSE file.
