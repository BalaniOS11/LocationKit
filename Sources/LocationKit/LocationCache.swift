import Foundation

actor LocationCache {
    private var countries: [Country]?
    private var statesByCountryId: [Int: [State]] = [:]
    private var citiesByStateId: [Int: [City]] = [:]

    func getCountries() -> [Country]? { countries }
    func setCountries(_ value: [Country]) { countries = value }

    func getStates(countryId: Int) -> [State]? { statesByCountryId[countryId] }
    func setStates(_ value: [State], countryId: Int) { statesByCountryId[countryId] = value }

    func getCities(stateId: Int) -> [City]? { citiesByStateId[stateId] }
    func setCities(_ value: [City], stateId: Int) { citiesByStateId[stateId] = value }
}

