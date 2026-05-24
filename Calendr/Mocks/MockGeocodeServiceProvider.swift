//
//  MockGeocodeServiceProvider.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

#if DEBUG

import Foundation

class MockGeocodeServiceProvider: GeocodeServiceProviding {

    func geocodeLocation(_ location: String) async -> Coordinates? {
        return nil
    }
}

#endif
