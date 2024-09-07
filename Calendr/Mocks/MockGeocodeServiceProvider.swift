//
//  MockGeocodeServiceProvider.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

import Foundation

class MockGeocodeServiceProvider: GeocodeServiceProviding {

    func geocodeAddressString(_ address: String) async -> Coordinates? {
        return nil
    }
}
