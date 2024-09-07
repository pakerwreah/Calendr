//
//  GeocodeServiceProvider.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

import CoreLocation

typealias Coordinates = CLLocationCoordinate2D

protocol GeocodeServiceProviding {
    func geocodeAddressString(_ address: String) async -> Coordinates?
}

class GeocodeServiceProvider<LocationCache: Cache>: GeocodeServiceProviding
where LocationCache.Key == String, LocationCache.Value == Coordinates? {

    private let geocoder = CLGeocoder()
    private let cache: LocationCache

    init(cache: LocationCache = LRUCache(capacity: 50)) {
        self.cache = cache
    }

    func geocodeAddressString(_ address: String) async -> Coordinates? {

        guard !address.isEmpty else { return nil }
        
        if let location = cache.get(address) {
            print("Cache hit for \"\(address)\"")
            return location
        }

        do {
            let coordinates = try await geocoder.geocodeAddressString(address).first?.location?.coordinate
            cache.set(address, coordinates)
            return coordinates
        } catch {
            guard let error = error as? CLError else {
                print(error.localizedDescription)
                return nil
            }
            guard error.code == .geocodeFoundNoResult else {
                print("Geocode failed with code", error.errorCode)
                return nil
            }
            print("Geocode found no result for \"\(address)\"")
            cache.set(address, nil)
            return nil
        }
    }
}
