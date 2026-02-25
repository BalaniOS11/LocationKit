import Foundation

public struct CombinedJSONLocationProvider: LocationProviding {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let resourceName: String
    private let store: Store

    public init(
        bundle: Bundle = .module,
        decoder: JSONDecoder = .init(),
        resourceName: String = "countries+states+cities"
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.resourceName = resourceName
        self.store = Store(bundle: bundle, decoder: decoder, resourceName: resourceName)
    }

    public func fetchCountries() async throws -> [Country] {
        try await store.load().countries
    }

    public func fetchStates(countryId: Int) async throws -> [State] {
        try await store.load().statesByCountryId[countryId] ?? []
    }

    public func fetchCities(stateId: Int) async throws -> [City] {
        try await store.load().citiesByStateId[stateId] ?? []
    }
}

private actor Store {
    struct Cache: Sendable {
        let countries: [Country]
        let statesByCountryId: [Int: [State]]
        let citiesByStateId: [Int: [City]]
    }

    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let resourceName: String
    private var cached: Cache?

    init(bundle: Bundle, decoder: JSONDecoder, resourceName: String) {
        self.bundle = bundle
        self.decoder = decoder
        self.resourceName = resourceName
    }

    func load() throws -> Cache {
        if let cached { return cached }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LocationKitError.resourceMissing("\(resourceName).json")
        }
        let data = try Data(contentsOf: url)
        let dto: [CountryDTO]
        do {
            dto = try decoder.decode([CountryDTO].self, from: data)
        } catch {
            throw LocationKitError.decodingFailed
        }

        let countries = dto.map { Country(id: $0.id, name: $0.name) }

        var statesByCountryId: [Int: [State]] = [:]
        var citiesByStateId: [Int: [City]] = [:]

        for country in dto {
            let states = (country.states ?? []).map { State(id: $0.id, name: $0.name, countryId: country.id) }
            statesByCountryId[country.id] = states
            for state in (country.states ?? []) {
                let cities = (state.cities ?? []).map { City(id: $0.id, name: $0.name, stateId: state.id) }
                citiesByStateId[state.id] = cities
            }
        }

        let cache = Cache(
            countries: countries,
            statesByCountryId: statesByCountryId,
            citiesByStateId: citiesByStateId
        )
        self.cached = cache
        return cache
    }
}

private struct CountryDTO: Decodable {
    let id: Int
    let name: String
    let states: [StateDTO]?
}

private struct StateDTO: Decodable {
    let id: Int
    let name: String
    let cities: [CityDTO]?
}

private struct CityDTO: Decodable {
    let id: Int
    let name: String
}

