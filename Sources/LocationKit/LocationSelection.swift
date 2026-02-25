import Foundation

public struct LocationSelection: Codable, Hashable, Sendable {
    public var countryId: Int?
    public var countryName: String
    public var stateId: Int?
    public var stateName: String
    public var cityId: Int?
    public var cityName: String

    public var isCustomCountry: Bool
    public var isCustomState: Bool
    public var isCustomCity: Bool

    public init(
        countryId: Int? = nil,
        countryName: String = "",
        stateId: Int? = nil,
        stateName: String = "",
        cityId: Int? = nil,
        cityName: String = "",
        isCustomCountry: Bool = false,
        isCustomState: Bool = false,
        isCustomCity: Bool = false
    ) {
        self.countryId = countryId
        self.countryName = countryName
        self.stateId = stateId
        self.stateName = stateName
        self.cityId = cityId
        self.cityName = cityName
        self.isCustomCountry = isCustomCountry
        self.isCustomState = isCustomState
        self.isCustomCity = isCustomCity
    }

    public var isComplete: Bool {
        !countryName.isEmpty && !stateName.isEmpty && !cityName.isEmpty
    }
}

