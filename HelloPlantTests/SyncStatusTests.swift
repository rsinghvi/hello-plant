import Testing
@testable import HelloPlant

@MainActor
struct SyncStatusTests {
    @Test func mapsLifecycleEvents() {
        let observer = SyncStatusObserver()
        observer.apply(.started)
        #expect(observer.status == .syncing)
        observer.apply(.succeeded)
        #expect(observer.status == .idle)
        observer.apply(.failed("No connection"))
        #expect(observer.status == .error("No connection"))
    }
}
