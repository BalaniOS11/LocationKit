import SwiftUI

public struct LocationAddressSelectorView: View {
    @SwiftUI.StateObject private var viewModel: LocationPickerViewModel
    @Binding private var selection: LocationSelection

    private let allowCustomEntry: Bool

    @SwiftUI.State private var isManualCountry = false
    @SwiftUI.State private var isManualState = false
    @SwiftUI.State private var isManualCity = false

    @SwiftUI.State private var manualCountry = ""
    @SwiftUI.State private var manualState = ""
    @SwiftUI.State private var manualCity = ""

    public init(
        viewModel: @autoclosure @escaping () -> LocationPickerViewModel,
        selection: Binding<LocationSelection>,
        allowCustomEntry: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _selection = selection
        self.allowCustomEntry = allowCustomEntry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(
                title: "Country",
                placeholderSelect: "Select country",
                placeholderManual: "Enter country",
                isManual: $isManualCountry,
                manualText: $manualCountry,
                items: viewModel.countries,
                selected: $viewModel.selectedCountry,
                disabledSelect: false,
                disabledManual: false,
                isLoading: viewModel.loadingPhase == .countries,
                emptyMessage: "No countries available",
                itemTitle: { $0.name },
                onManualChanged: { _ in
                    if isManualCountry {
                        viewModel.selectedCountry = nil
                    }
                }
            )

            field(
                title: "State",
                placeholderSelect: "Select state",
                placeholderManual: "Enter state",
                isManual: $isManualState,
                manualText: $manualState,
                items: viewModel.states,
                selected: $viewModel.selectedState,
                disabledSelect: !canUseStateDropdown,
                disabledManual: !canUseStateManual,
                isLoading: isLoadingStates,
                emptyMessage: "No states available",
                itemTitle: { $0.name },
                onManualChanged: { _ in
                    if isManualState {
                        viewModel.selectedState = nil
                    }
                }
            )

            field(
                title: "City",
                placeholderSelect: "Select city",
                placeholderManual: "Enter city",
                isManual: $isManualCity,
                manualText: $manualCity,
                items: viewModel.cities,
                selected: $viewModel.selectedCity,
                disabledSelect: !canUseCityDropdown,
                disabledManual: !canUseCityManual,
                isLoading: isLoadingCities,
                emptyMessage: "No cities available",
                itemTitle: { $0.name },
                onManualChanged: { _ in
                    if isManualCity {
                        viewModel.selectedCity = nil
                    }
                }
            )

            if let error = viewModel.errorMessage, !error.isEmpty {
                HStack(spacing: 12) {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                    Button("Retry") { viewModel.retry() }
                        .font(.footnote)
                }
            }
        }
        .task {
            if viewModel.countries.isEmpty {
                viewModel.loadCountries()
            }
        }
        .onChange(of: viewModel.selectedCountry?.id) { _, _ in
            if viewModel.selectedCountry != nil {
                isManualCountry = false
                manualCountry = ""
            } else if isManualCountry {
                viewModel.selectedState = nil
                viewModel.selectedCity = nil
                isManualState = true
                isManualCity = true
            }
            manualState = ""
            manualCity = ""
            recomputeSelection()
        }
        .onChange(of: viewModel.selectedState?.id) { _, _ in
            if viewModel.selectedState != nil {
                isManualState = false
                manualState = ""
            }
            manualCity = ""
            recomputeSelection()
        }
        .onChange(of: viewModel.selectedCity?.id) { _, _ in
            if viewModel.selectedCity != nil {
                isManualCity = false
                manualCity = ""
            }
            recomputeSelection()
        }
        .onChange(of: manualCountry) { _, _ in recomputeSelection() }
        .onChange(of: manualState) { _, _ in recomputeSelection() }
        .onChange(of: manualCity) { _, _ in recomputeSelection() }
        .onChange(of: isManualCountry) { _, newValue in
            guard allowCustomEntry else { return }
            if newValue {
                viewModel.selectedCountry = nil
                viewModel.selectedState = nil
                viewModel.selectedCity = nil
                isManualState = true
                isManualCity = true
            } else {
                manualCountry = ""
                manualState = ""
                manualCity = ""
            }
            recomputeSelection()
        }
        .onChange(of: isManualState) { _, newValue in
            guard allowCustomEntry else { return }
            if newValue {
                viewModel.selectedState = nil
                viewModel.selectedCity = nil
                isManualCity = true
            } else {
                manualState = ""
                manualCity = ""
            }
            recomputeSelection()
        }
        .onChange(of: isManualCity) { _, newValue in
            guard allowCustomEntry else { return }
            if newValue {
                viewModel.selectedCity = nil
            } else {
                manualCity = ""
            }
            recomputeSelection()
        }
        .onAppear {
            hydrateFromInitialSelection()
            recomputeSelection()
        }
    }

    private func field<Item: Identifiable & Hashable>(
        title: LocalizedStringKey,
        placeholderSelect: LocalizedStringKey,
        placeholderManual: LocalizedStringKey,
        isManual: Binding<Bool>,
        manualText: Binding<String>,
        items: [Item],
        selected: Binding<Item?>,
        disabledSelect: Bool,
        disabledManual: Bool,
        isLoading: Bool,
        emptyMessage: LocalizedStringKey,
        itemTitle: @escaping (Item) -> String,
        onManualChanged: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if allowCustomEntry {
                Toggle("Enter manually", isOn: isManual)
                    .font(.footnote)
                    .disabled(disabledManual && isManual.wrappedValue == false)
            }

            if allowCustomEntry, isManual.wrappedValue {
                TextField(placeholderManual, text: manualText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .disabled(disabledManual)
                    .onChange(of: manualText.wrappedValue) { _, newValue in
                        onManualChanged(newValue)
                    }
            } else {
                SearchableSheetPicker(
                    title: title,
                    placeholder: disabledSelect ? "Select previous first" : placeholderSelect,
                    items: items,
                    selection: selected,
                    disabled: disabledSelect,
                    isLoading: isLoading,
                    emptyMessage: emptyMessage,
                    itemTitle: itemTitle
                )
                .padding(.vertical, 4)
            }
        }
    }

    private var canUseStateDropdown: Bool {
        viewModel.selectedCountry != nil
    }

    private var canUseStateManual: Bool {
        if viewModel.selectedCountry != nil { return true }
        return !manualCountry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canUseCityDropdown: Bool {
        viewModel.selectedState != nil
    }

    private var canUseCityManual: Bool {
        if viewModel.selectedState != nil { return true }
        return !manualState.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isLoadingStates: Bool {
        if case .states = viewModel.loadingPhase { return true }
        return false
    }

    private var isLoadingCities: Bool {
        if case .cities = viewModel.loadingPhase { return true }
        return false
    }

    private func hydrateFromInitialSelection() {
        isManualCountry = selection.isCustomCountry
        isManualState = selection.isCustomState
        isManualCity = selection.isCustomCity
        manualCountry = selection.isCustomCountry ? selection.countryName : ""
        manualState = selection.isCustomState ? selection.stateName : ""
        manualCity = selection.isCustomCity ? selection.cityName : ""
    }

    private func recomputeSelection() {
        let countryFromPicker = viewModel.selectedCountry
        let stateFromPicker = viewModel.selectedState
        let cityFromPicker = viewModel.selectedCity

        let countryName = isManualCountry
            ? manualCountry.trimmingCharacters(in: .whitespacesAndNewlines)
            : (countryFromPicker?.name ?? "")
        let stateName = isManualState
            ? manualState.trimmingCharacters(in: .whitespacesAndNewlines)
            : (stateFromPicker?.name ?? "")
        let cityName = isManualCity
            ? manualCity.trimmingCharacters(in: .whitespacesAndNewlines)
            : (cityFromPicker?.name ?? "")

        selection = LocationSelection(
            countryId: isManualCountry ? nil : countryFromPicker?.id,
            countryName: countryName,
            stateId: isManualState ? nil : stateFromPicker?.id,
            stateName: stateName,
            cityId: isManualCity ? nil : cityFromPicker?.id,
            cityName: cityName,
            isCustomCountry: isManualCountry,
            isCustomState: isManualState,
            isCustomCity: isManualCity
        )
    }
}

#if DEBUG
private struct AddressPreviewProvider: LocationProviding {
    func fetchCountries() async throws -> [Country] {
        [
            .init(id: 1, name: "United States"),
            .init(id: 2, name: "Canada"),
        ]
    }
    func fetchStates(countryId: Int) async throws -> [State] {
        switch countryId {
        case 1: return [.init(id: 101, name: "California", countryId: 1)]
        case 2: return [.init(id: 201, name: "Ontario", countryId: 2)]
        default: return []
        }
    }
    func fetchCities(stateId: Int) async throws -> [City] {
        switch stateId {
        case 101: return [.init(id: 1001, name: "San Francisco", stateId: 101)]
        case 201: return [.init(id: 2001, name: "Toronto", stateId: 201)]
        default: return []
        }
    }
}

#Preview {
    struct Demo: View {
        @State var selection = LocationSelection()
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                LocationAddressSelectorView(
                    viewModel: LocationPickerViewModel(provider: AddressPreviewProvider()),
                    selection: $selection,
                    allowCustomEntry: true
                )
                Text("Response: \(selection.countryName), \(selection.stateName), \(selection.cityName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    return Demo()
}
#endif

