import XCTest
@testable import LocationKit

final class LocationPickerViewModelTests: XCTestCase {
    func testCountryChangeResetsAndFetchesStatesAndCaches() async {
        let provider = TestProvider()
        let cache = LocationCache()
        let viewModel = await MainActor.run { LocationPickerViewModel(provider: provider, cache: cache) }

        let usa = Country(id: 1, name: "United States")
        let canada = Country(id: 2, name: "Canada")

        await MainActor.run {
            viewModel.selectedCountry = usa
        }

        await waitUntil { await MainActor.run { viewModel.states.count == 2 } }
        XCTAssertEqual(await provider.calls.statesByCountry[1], 1)

        await MainActor.run {
            viewModel.selectedState = viewModel.states.first
        }
        await waitUntil { await MainActor.run { viewModel.cities.count == 2 } }

        await MainActor.run {
            viewModel.selectedCountry = canada
        }
        XCTAssertNil(await MainActor.run { viewModel.selectedState })
        XCTAssertNil(await MainActor.run { viewModel.selectedCity })
        XCTAssertTrue(await MainActor.run { viewModel.cities.isEmpty })

        await waitUntil { await MainActor.run { viewModel.states.count == 1 } }
        XCTAssertEqual(await provider.calls.statesByCountry[2], 1)

        await MainActor.run {
            viewModel.selectedCountry = usa
        }
        await waitUntil { await MainActor.run { viewModel.states.count == 2 } }
        XCTAssertEqual(await provider.calls.statesByCountry[1], 1, "Expected cache hit (no additional network call).")
    }

    func testStateChangeResetsAndFetchesCities() async {
        let provider = TestProvider()
        let cache = LocationCache()
        let viewModel = await MainActor.run { LocationPickerViewModel(provider: provider, cache: cache) }

        await MainActor.run {
            viewModel.selectedCountry = Country(id: 1, name: "United States")
        }
        await waitUntil { await MainActor.run { viewModel.states.count == 2 } }

        let ca = await MainActor.run { viewModel.states.first(where: { $0.id == 101 })! }
        let ny = await MainActor.run { viewModel.states.first(where: { $0.id == 102 })! }

        await MainActor.run { viewModel.selectedState = ca }
        await waitUntil { await MainActor.run { viewModel.cities.map(\.id) == [1001, 1002] } }

        await MainActor.run { viewModel.selectedCity = viewModel.cities.first }
        await MainActor.run { viewModel.selectedState = ny }

        XCTAssertNil(await MainActor.run { viewModel.selectedCity })
        await waitUntil { await MainActor.run { viewModel.cities.map(\.id) == [1003] } }
    }

    private func waitUntil(
        timeout: TimeInterval = 1.0,
        pollEvery: UInt64 = 20_000_000,
        condition: @escaping @Sendable () async -> Bool
    ) async {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await condition() { return }
            try? await Task.sleep(nanoseconds: pollEvery)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private actor CallCounts {
    var countries: Int = 0
    var statesByCountry: [Int: Int] = [:]
    var citiesByState: [Int: Int] = [:]

    func incrementCountries() {
        countries += 1
    }

    func incrementStates(countryId: Int) {
        statesByCountry[countryId, default: 0] += 1
    }

    func incrementCities(stateId: Int) {
        citiesByState[stateId, default: 0] += 1
    }
}

private final class TestProvider: LocationProviding, @unchecked Sendable {
    let calls = CallCounts()

    func fetchCountries() async throws -> [Country] {
        await calls.incrementCountries()
        return [
            .init(id: 1, name: "United States"),
            .init(id: 2, name: "Canada"),
        ]
    }

    func fetchStates(countryId: Int) async throws -> [State] {
        await calls.incrementStates(countryId: countryId)
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
        await calls.incrementCities(stateId: stateId)
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
        default:
            return []
        }
    }
}
