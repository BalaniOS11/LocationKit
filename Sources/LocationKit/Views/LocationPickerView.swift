import SwiftUI

public struct LocationPickerView: View {
    @SwiftUI.StateObject private var viewModel: LocationPickerViewModel

    public init(viewModel: @autoclosure @escaping () -> LocationPickerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SearchableSheetPicker(
                title: "Country",
                placeholder: "Select country",
                items: viewModel.countries,
                selection: $viewModel.selectedCountry,
                disabled: false,
                isLoading: viewModel.loadingPhase == .countries,
                emptyMessage: "No countries available",
                itemTitle: { $0.name }
            )
            .padding(.vertical, 4)

            SearchableSheetPicker(
                title: "State",
                placeholder: viewModel.selectedCountry == nil ? "Select country first" : "Select state",
                items: viewModel.states,
                selection: $viewModel.selectedState,
                disabled: viewModel.selectedCountry == nil,
                isLoading: isLoadingStates,
                emptyMessage: "No states available",
                itemTitle: { $0.name }
            )
            .padding(.vertical, 4)

            SearchableSheetPicker(
                title: "City",
                placeholder: viewModel.selectedState == nil ? "Select state first" : "Select city",
                items: viewModel.cities,
                selection: $viewModel.selectedCity,
                disabled: viewModel.selectedState == nil,
                isLoading: isLoadingCities,
                emptyMessage: "No cities available",
                itemTitle: { $0.name }
            )
            .padding(.vertical, 4)

            if let error = viewModel.errorMessage {
                HStack(spacing: 12) {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                    Button("Retry") { viewModel.retry() }
                        .font(.footnote)
                }
            }

            if viewModel.selectedCountry != nil, viewModel.states.isEmpty, !isLoadingStates, viewModel.errorMessage == nil {
                Text("No states available")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            if viewModel.selectedState != nil, viewModel.cities.isEmpty, !isLoadingCities, viewModel.errorMessage == nil {
                Text("No cities available")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .task {
            if viewModel.countries.isEmpty {
                viewModel.loadCountries()
            }
        }
    }

    private var isLoadingStates: Bool {
        if case .states = viewModel.loadingPhase { return true }
        return false
    }

    private var isLoadingCities: Bool {
        if case .cities = viewModel.loadingPhase { return true }
        return false
    }
}

#if DEBUG
private struct PreviewProviderMock: LocationProviding {
    func fetchCountries() async throws -> [Country] {
        [
            .init(id: 1, name: "United States"),
            .init(id: 2, name: "Canada"),
        ]
    }

    func fetchStates(countryId: Int) async throws -> [State] {
        switch countryId {
        case 1: return [.init(id: 101, name: "California", countryId: 1), .init(id: 102, name: "New York", countryId: 1)]
        case 2: return [.init(id: 201, name: "Ontario", countryId: 2)]
        default: return []
        }
    }

    func fetchCities(stateId: Int) async throws -> [City] {
        switch stateId {
        case 101: return [.init(id: 1001, name: "San Francisco", stateId: 101), .init(id: 1002, name: "Los Angeles", stateId: 101)]
        case 102: return [.init(id: 1003, name: "New York City", stateId: 102)]
        case 201: return [.init(id: 2001, name: "Toronto", stateId: 201)]
        default: return []
        }
    }
}

#Preview {
    LocationPickerView(viewModel: LocationPickerViewModel(provider: PreviewProviderMock()))
}
#endif
