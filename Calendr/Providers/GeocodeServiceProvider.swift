//
//  GeocodeServiceProvider.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

import CoreLocation

struct Coordinates: Hashable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
}

extension Coordinates {

    init(_ location: CLLocationCoordinate2D) {
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
}

extension CLLocationCoordinate2D {

    init(_ location: Coordinates) {
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
}

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
            print("Cache hit for address: \"\(address)\"")
            return location
        }

        do {
            guard let location = try await geocoder.geocodeAddressString(address).first?.location?.coordinate else {
                throw CLError(.geocodeFoundNoResult)
            }
            let coordinates = Coordinates(location)
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
