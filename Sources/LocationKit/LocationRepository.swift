import Foundation

public actor LocationRepository {
    private let provider: LocationProviding

    private var countriesCache: [Country]?
    private var statesCache: [Int: [State]] = [:]   // countryId -> states
    private var citiesCache: [Int: [City]] = [:]    // stateId -> cities

    public init(provider: LocationProviding) {
        self.provider = provider
    }

    public func countries(forceRefresh: Bool = false) async throws -> [Country] {
        if !forceRefresh, let countriesCache { return countriesCache }
        let result = try await provider.fetchCountries()
        countriesCache = result
        return result
    }

    public func states(countryId: Int, forceRefresh: Bool = false) async throws -> [State] {
        if !forceRefresh, let cached = statesCache[countryId] { return cached }
        let result = try await provider.fetchStates(countryId: countryId)
        statesCache[countryId] = result
        return result
    }

    public func cities(stateId: Int, forceRefresh: Bool = false) async throws -> [City] {
        if !forceRefresh, let cached = citiesCache[stateId] { return cached }
        let result = try await provider.fetchCities(stateId: stateId)
        citiesCache[stateId] = result
        return result
    }

    public func clearCache() {
        countriesCache = nil
        statesCache = [:]
        citiesCache = [:]
    }
}

