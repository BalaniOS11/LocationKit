import Foundation

public enum LocationKit { }

public extension LocationKit {
    static func remote(baseURL: URL, session: URLSession = .shared) -> LocationProviding {
        RemoteLocationProvider(config: LocationAPIConfig(baseURL: baseURL), session: session)
    }

    static func bundledCombinedJSON(resourceName: String = "countries+states+cities") -> LocationProviding {
        CombinedJSONLocationProvider(resourceName: resourceName)
    }

    static func remoteWithCombinedBundledFallback(baseURL: URL, session: URLSession = .shared) -> LocationProviding {
        FallbackLocationProvider(primary: remote(baseURL: baseURL, session: session), fallback: bundledCombinedJSON())
    }
}
