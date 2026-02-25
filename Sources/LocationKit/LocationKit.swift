import Foundation

public enum LocationKit { }

public extension LocationKit {
    static func remote(baseURL: URL, session: URLSession = .shared) -> LocationProviding {
        RemoteLocationProvider(config: LocationAPIConfig(baseURL: baseURL), session: session)
    }

    static func bundledJSON() -> LocationProviding {
        BundledJSONLocationProvider(bundle: .module)
    }

    static func remoteWithBundledFallback(baseURL: URL, session: URLSession = .shared) -> LocationProviding {
        FallbackLocationProvider(primary: remote(baseURL: baseURL, session: session), fallback: bundledJSON())
    }
}

