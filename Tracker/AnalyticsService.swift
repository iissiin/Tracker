import AppMetricaCore

struct AnalyticsService {
    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: "3c803b9a-9886-4df0-923b-119489a504f4") else { return }
        AppMetrica.activate(with: configuration)
    }

    func report(event: String, params: [AnyHashable: Any]) {
        AppMetrica.reportEvent(name: "EVENT", parameters: params, onFailure: { error in
            print("REPORT ERROR: \(error.localizedDescription)")
        })
        print("Analytics Event: \(event), Parameters: \(params)")
    }
}
