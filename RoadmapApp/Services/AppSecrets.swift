import Foundation

enum AppSecrets {
    static var workerBaseURL: String {
        (Bundle.main.infoDictionary?["RoadmapWorkerURL"] as? String) ?? ""
    }

    static var hasValidWorkerURL: Bool {
        let url = workerBaseURL
        return !url.isEmpty && !url.contains("YOUR_WORKER_URL_HERE")
    }
}
