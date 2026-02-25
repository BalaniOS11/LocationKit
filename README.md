# LocationKit

Swift Package for hierarchical location selection (Country → State → City) with SwiftUI + MVVM.

## Using the bundled `countries+states+cities.json`

This repo already includes `/Users/anilkumar/Documents/GitHub/LocationKit/Sources/LocationKit/Resources/countries+states+cities.json`.

Create a provider that reads it:

```swift
import LocationKit

let provider = LocationKit.bundledCombinedJSON()
let vm = LocationPickerViewModel(provider: provider)
```

## SwiftUI address screen (dropdown + manual entry + response)

`LocationAddressSelectorView` supports either selecting from dropdowns or entering custom values, and writes a single `LocationSelection` “response” object you can send to your backend.

```swift
import SwiftUI
import LocationKit

struct AddressScreen: View {
    @State private var location = LocationSelection()

    private var viewModel: LocationPickerViewModel {
        LocationPickerViewModel(provider: LocationKit.bundledCombinedJSON())
    }

    var body: some View {
        Form {
            Section("Location") {
                LocationAddressSelectorView(
                    viewModel: viewModel,
                    selection: $location,
                    allowCustomEntry: true
                )
            }

            Button("Submit") {
                // Example payload
                let payload = location
                let data = try? JSONEncoder().encode(payload)
                print(String(data: data ?? Data(), encoding: .utf8) ?? "")
            }
            .disabled(!location.isComplete)
        }
    }
}
```

