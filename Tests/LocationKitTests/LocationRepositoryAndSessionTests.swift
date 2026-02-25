import XCTest
@testable import LocationKit

final class LocationRepositoryAndSessionTests: XCTestCase {
    func testBundledCombinedJSONDecodes() async throws {
        let provider = CombinedJSONLocationProvider(bundle: .module)
        let countries = try await provider.fetchCountries()
        XCTAssertFalse(countries.isEmpty)

        let afghanistan = countries.first(where: { $0.id == 1 })
        XCTAssertEqual(afghanistan?.name, "Afghanistan")

        let states = try await provider.fetchStates(countryId: 1)
        XCTAssertFalse(states.isEmpty)

        // From the bundled file, Afghanistan has state id 3901 (Badakhshan).
        let cities = try await provider.fetchCities(stateId: 3901)
        XCTAssertFalse(cities.isEmpty)
    }

    func testSelectionFlowResetsChildrenAndFetches() async throws {
        let provider = CountingProvider()
        let repository = LocationRepository(provider: provider)
        let session = LocationSelectionSession(repository: repository)

        let countries = try await session.loadCountries()
        XCTAssertEqual(countries.map(\.id), [1, 2])
        XCTAssertEqual(await provider.calls.countriesCount(), 1)

        let statesUS = try await session.selectCountry(countries[0])
        XCTAssertEqual(statesUS.map(\.id), [101, 102])
        XCTAssertEqual(await provider.calls.statesCount(countryId: 1), 1)
        XCTAssertNil(await session.selectedState)
        XCTAssertNil(await session.selectedCity)

        let citiesCA = try await session.selectState(statesUS[0])
        XCTAssertEqual(citiesCA.map(\.id), [1001, 1002])
        XCTAssertEqual(await provider.calls.citiesCount(stateId: 101), 1)

        await session.selectCity(citiesCA[0])
        let response1 = await session.response()
        XCTAssertEqual(response1.countryId, 1)
        XCTAssertEqual(response1.stateId, 101)
        XCTAssertEqual(response1.cityId, 1001)

        let statesCA = try await session.selectCountry(countries[1])
        XCTAssertEqual(statesCA.map(\.id), [201])
        XCTAssertNil(await session.selectedState)
        XCTAssertNil(await session.selectedCity)
    }

    func testRepositoryCachesByDefault() async throws {
        let provider = CountingProvider()
        let repository = LocationRepository(provider: provider)

        _ = try await repository.countries()
        _ = try await repository.countries()
        XCTAssertEqual(await provider.calls.countriesCount(), 1)

        _ = try await repository.states(countryId: 1)
        _ = try await repository.states(countryId: 1)
        XCTAssertEqual(await provider.calls.statesCount(countryId: 1), 1)

        _ = try await repository.cities(stateId: 101)
        _ = try await repository.cities(stateId: 101)
        XCTAssertEqual(await provider.calls.citiesCount(stateId: 101), 1)
    }
}

private actor Calls {
    var countries: Int = 0
    var statesByCountry: [Int: Int] = [:]
    var citiesByState: [Int: Int] = [:]

    func incCountries() { countries += 1 }
    func incStates(countryId: Int) { statesByCountry[countryId, default: 0] += 1 }
    func incCities(stateId: Int) { citiesByState[stateId, default: 0] += 1 }

    func countriesCount() -> Int { countries }
    func statesCount(countryId: Int) -> Int { statesByCountry[countryId, default: 0] }
    func citiesCount(stateId: Int) -> Int { citiesByState[stateId, default: 0] }
}

private final class CountingProvider: LocationProviding, @unchecked Sendable {
    let calls = Calls()

    func fetchCountries() async throws -> [Country] {
        await calls.incCountries()
        return [
            .init(id: 1, name: "United States"),
            .init(id: 2, name: "Canada"),
        ]
    }

    func fetchStates(countryId: Int) async throws -> [State] {
        await calls.incStates(countryId: countryId)
        switch countryId {
        case 1:
            return [
                .init(id: 101, name: "California", countryId: 1),
                .init(id: 102, name: "New York", countryId: 1),
            ]
        case 2:
            return [
                .init(id: 201, name: "Ontario", countryId: 2),
            ]
        default:
            return []
        }
    }

    func fetchCities(stateId: Int) async throws -> [City] {
        await calls.incCities(stateId: stateId)
        switch stateId {
        case 101:
            return [
                .init(id: 1001, name: "San Francisco", stateId: 101),
                .init(id: 1002, name: "Los Angeles", stateId: 101),
            ]
        case 102:
            return [
                .init(id: 1003, name: "New York City", stateId: 102),
            ]
        case 201:
            return [
                .init(id: 2001, name: "Toronto", stateId: 201),
            ]
        default:
            return []
        }
    }
}
