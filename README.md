# LocationKit

Swift Package that provides hierarchical location data (Country → State → City) as a reusable SDK (no UI).

## Using the bundled `countries+states+cities.json`

This repo already includes `/Users/anilkumar/Documents/GitHub/LocationKit/Sources/LocationKit/Resources/countries+states+cities.json`.

Create a provider that reads it, then use `LocationRepository` and `LocationSelectionSession` to drive your app’s UI flow:

```swift
import LocationKit

let provider = LocationKit.bundledCombinedJSON()
let repository = LocationRepository(provider: provider)
let session = LocationSelectionSession(repository: repository)

let countries = try await session.loadCountries()
let states = try await session.selectCountry(countries.first)
let cities = try await session.selectState(states.first)
await session.selectCity(cities.first)

let response = await session.response() // Codable payload to send to your API
```
