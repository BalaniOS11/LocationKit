//
//  Models.swift
//  LocationKit
//
//  Created by Balan iOS on 25/02/26.
//

import Foundation

public struct CountryDatum: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct StateDatum: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let countryId: Int

    public init(id: Int, name: String, countryId: Int) {
        self.id = id
        self.name = name
        self.countryId = countryId
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryId = "country_id"
    }
}

public struct CityDatum: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let stateId: Int

    public init(id: Int, name: String, stateId: Int) {
        self.id = id
        self.name = name
        self.stateId = stateId
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case stateId = "state_id"
    }
}

