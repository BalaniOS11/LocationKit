import Foundation

public enum LocationKitError: Error, LocalizedError, Sendable, Equatable {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case resourceMissing(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL: return "Invalid base URL."
        case .invalidResponse: return "Invalid server response."
        case .httpStatus(let code): return "Request failed (HTTP \(code))."
        case .decodingFailed: return "Failed to decode server response."
        case .resourceMissing(let name): return "Missing bundled resource: \(name)."
        case .cancelled: return "Request cancelled."
        }
    }
}

public protocol LocationProviding: Sendable {
    func fetchCountries() async throws -> [CountryDatum]
    func fetchStates(countryId: Int) async throws -> [StateDatum]
    func fetchCities(stateId: Int) async throws -> [CityDatum]
}

public struct LocationAPIConfig: Sendable {
    public var baseURL: URL
    public var countriesPath: String
    public var statesPath: String
    public var citiesPath: String
    public var countryQueryKey: String
    public var stateQueryKey: String

    public init(
        baseURL: URL,
        countriesPath: String = "/countries",
        statesPath: String = "/states",
        citiesPath: String = "/cities",
        countryQueryKey: String = "country_id",
        stateQueryKey: String = "state_id"
    ) {
        self.baseURL = baseURL
        self.countriesPath = countriesPath
        self.statesPath = statesPath
        self.citiesPath = citiesPath
        self.countryQueryKey = countryQueryKey
        self.stateQueryKey = stateQueryKey
    }
}

public struct RemoteLocationProvider: LocationProviding {
    private let config: LocationAPIConfig
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        config: LocationAPIConfig,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init()
    ) {
        self.config = config
        self.session = session
        self.decoder = decoder
    }

    public func fetchCountries() async throws -> [CountryDatum] {
        try await fetch(path: config.countriesPath, queryItems: [])
    }

    public func fetchStates(countryId: Int) async throws -> [StateDatum] {
        try await fetch(
            path: config.statesPath,
            queryItems: [.init(name: config.countryQueryKey, value: String(countryId))]
        )
    }

    public func fetchCities(stateId: Int) async throws -> [CityDatum] {
        try await fetch(
            path: config.citiesPath,
            queryItems: [.init(name: config.stateQueryKey, value: String(stateId))]
        )
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: true)
        if components == nil, let base = URLComponents(string: config.baseURL.absoluteString) {
            components = base
        }
        guard var urlComponents = components else { throw LocationKitError.invalidBaseURL }

        let existingPath = urlComponents.path
        if path.hasPrefix("/") {
            urlComponents.path = existingPath + path
        } else {
            urlComponents.path = existingPath + "/" + path
        }
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems

        guard let url = urlComponents.url else { throw LocationKitError.invalidBaseURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw LocationKitError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw LocationKitError.httpStatus(http.statusCode) }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw LocationKitError.decodingFailed
            }
        } catch is CancellationError {
            throw LocationKitError.cancelled
        }
    }
}

public struct FallbackLocationProvider: LocationProviding {
    private let primary: LocationProviding
    private let fallback: LocationProviding

    public init(primary: LocationProviding, fallback: LocationProviding) {
        self.primary = primary
        self.fallback = fallback
    }

    public func fetchCountries() async throws -> [CountryDatum] {
        do { return try await primary.fetchCountries() } catch { return try await fallback.fetchCountries() }
    }

    public func fetchStates(countryId: Int) async throws -> [StateDatum] {
        do { return try await primary.fetchStates(countryId: countryId) } catch { return try await fallback.fetchStates(countryId: countryId) }
    }

    public func fetchCities(stateId: Int) async throws -> [CityDatum] {
        do { return try await primary.fetchCities(stateId: stateId) } catch { return try await fallback.fetchCities(stateId: stateId) }
    }
}
