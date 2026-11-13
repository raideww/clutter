import SwiftUI

@main
struct ClutterApp: App {
    @State private var store = Store()
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .environment(library)
        }
    }
}
