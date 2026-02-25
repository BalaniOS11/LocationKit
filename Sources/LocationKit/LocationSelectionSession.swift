import Foundation

public actor LocationSelectionSession {
    public private(set) var selectedCountry: CountryDatum?
    public private(set) var selectedState: StateDatum?
    public private(set) var selectedCity: CityDatum?

    private let repository: LocationRepository

    public init(repository: LocationRepository) {
        self.repository = repository
    }

    public func loadCountries(forceRefresh: Bool = false) async throws -> [CountryDatum] {
        try await repository.countries(forceRefresh: forceRefresh)
    }

    public func selectCountry(_ country: CountryDatum?, forceRefresh: Bool = false) async throws -> [StateDatum] {
        if selectedCountry?.id != country?.id {
            selectedCountry = country
            selectedState = nil
            selectedCity = nil
        }
        guard let id = selectedCountry?.id else { return [] }
        return try await repository.states(countryId: id, forceRefresh: forceRefresh)
    }

    public func selectState(_ state: StateDatum?, forceRefresh: Bool = false) async throws -> [CityDatum] {
        if selectedState?.id != state?.id {
            selectedState = state
            selectedCity = nil
        }
        guard let id = selectedState?.id else { return [] }
        return try await repository.cities(stateId: id, forceRefresh: forceRefresh)
    }

    public func selectCity(_ city: CityDatum?) {
        selectedCity = city
    }

    public func reset() {
        selectedCountry = nil
        selectedState = nil
        selectedCity = nil
    }

    public func response() -> LocationSelection {
        LocationSelection(
            countryId: selectedCountry?.id,
            countryName: selectedCountry?.name ?? "",
            stateId: selectedState?.id,
            stateName: selectedState?.name ?? "",
            cityId: selectedCity?.id,
            cityName: selectedCity?.name ?? "",
            isCustomCountry: false,
            isCustomState: false,
            isCustomCity: false
        )
    }
}

