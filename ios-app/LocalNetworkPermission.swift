import Foundation

final class LocalNetworkPermission: NSObject, NetServiceBrowserDelegate {
    static let shared = LocalNetworkPermission()
    private let browser = NetServiceBrowser()
    private var started = false

    func trigger() {
        guard !started else { return }
        started = true
        browser.delegate = self
        browser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        browser.stop()
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) { }
}

