import Foundation
import Combine

@MainActor
public final class LocationPickerViewModel: ObservableObject {
    public enum LoadingPhase: Equatable, Sendable {
        case none
        case countries
        case states(countryId: Int)
        case cities(stateId: Int)
    }

    @Published public var selectedCountry: Country? {
        didSet {
            guard oldValue?.id != selectedCountry?.id else { return }
            selectedState = nil
            selectedCity = nil
            states = []
            cities = []
            errorMessage = nil
            if let id = selectedCountry?.id {
                fetchStates(countryId: id)
            }
        }
    }

    @Published public var selectedState: State? {
        didSet {
            guard oldValue?.id != selectedState?.id else { return }
            selectedCity = nil
            cities = []
            errorMessage = nil
            if let id = selectedState?.id {
                fetchCities(stateId: id)
            }
        }
    }

    @Published public var selectedCity: City?

    @Published public private(set) var countries: [Country] = []
    @Published public private(set) var states: [State] = []
    @Published public private(set) var cities: [City] = []

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var loadingPhase: LoadingPhase = .none
    @Published public var errorMessage: String?

    private let provider: LocationProviding
    private let cache: LocationCache

    private var countriesTask: Task<Void, Never>?
    private var statesTask: Task<Void, Never>?
    private var citiesTask: Task<Void, Never>?

    public init(provider: LocationProviding) {
        self.provider = provider
        self.cache = .init()
    }

    init(provider: LocationProviding, cache: LocationCache) {
        self.provider = provider
        self.cache = cache
    }

    public func loadCountries() {
        countriesTask?.cancel()
        countriesTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.loadingPhase = .countries
            defer {
                self.isLoading = false
                self.loadingPhase = .none
            }

            if let cached = await cache.getCountries(), !cached.isEmpty {
                self.countries = cached
                return
            }

            do {
                let result = try await provider.fetchCountries()
                self.countries = result
                await cache.setCountries(result)
                self.errorMessage = nil
            } catch let error as LocationKitError where error == .cancelled {
                return
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load countries."
            }
        }
    }

    public func retry() {
        errorMessage = nil
        if countries.isEmpty {
            loadCountries()
            return
        }
        if let countryId = selectedCountry?.id, states.isEmpty {
            fetchStates(countryId: countryId)
            return
        }
        if let stateId = selectedState?.id, cities.isEmpty {
            fetchCities(stateId: stateId)
            return
        }
    }

    private func fetchStates(countryId: Int) {
        statesTask?.cancel()
        statesTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.loadingPhase = .states(countryId: countryId)
            defer {
                self.isLoading = false
                self.loadingPhase = .none
            }

            if let cached = await cache.getStates(countryId: countryId) {
                self.states = cached
                return
            }

            do {
                let result = try await provider.fetchStates(countryId: countryId)
                self.states = result
                await cache.setStates(result, countryId: countryId)
                self.errorMessage = nil
            } catch let error as LocationKitError where error == .cancelled {
                return
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load states."
            }
        }
    }

    private func fetchCities(stateId: Int) {
        citiesTask?.cancel()
        citiesTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.loadingPhase = .cities(stateId: stateId)
            defer {
                self.isLoading = false
                self.loadingPhase = .none
            }

            if let cached = await cache.getCities(stateId: stateId) {
                self.cities = cached
                return
            }

            do {
                let result = try await provider.fetchCities(stateId: stateId)
                self.cities = result
                await cache.setCities(result, stateId: stateId)
                self.errorMessage = nil
            } catch let error as LocationKitError where error == .cancelled {
                return
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load cities."
            }
        }
    }
}
