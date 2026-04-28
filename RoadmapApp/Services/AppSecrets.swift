import Foundation

/// Where to find the deployed Cloudflare Worker. The URL itself is public
/// infrastructure (live at a `.workers.dev` endpoint) — the real secret is the
/// Anthropic API key, which lives on Cloudflare and never ships in the app.
///
/// Reads in this order:
///   1. `RoadmapWorkerURL` from `Info.plist` (set via xcconfig if you want
///      a per-environment override that doesn't get committed).
///   2. The hardcoded production URL below.
enum AppSecrets {
    static let defaultWorkerBaseURL = "https://roadmap-worker.imalabekov.workers.dev"

    static var workerBaseURL: String {
        if let url = Bundle.main.infoDictionary?["RoadmapWorkerURL"] as? String,
           !url.isEmpty,
           !url.contains("YOUR_WORKER_URL_HERE") {
            return url
        }
        return defaultWorkerBaseURL
    }

    static var hasValidWorkerURL: Bool {
        let url = workerBaseURL
        return !url.isEmpty && !url.contains("YOUR_WORKER_URL_HERE")
    }
}
