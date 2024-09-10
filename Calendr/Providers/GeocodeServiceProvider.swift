//
//  GeocodeServiceProvider.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

import CoreLocation
import MapKit

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

        let sanitized = address.replacingOccurrences(of: ["(", ")"], with: " ")

        do {
            let geocoderLocation = try await geocoderLocation(for: sanitized)
            let searchLocation = try await searchLocation(for: sanitized, in: geocoderLocation)

            guard let location = searchLocation ?? geocoderLocation else {
                cache.set(address, nil)
                return nil
            }

            let coordinates = Coordinates(location)
            cache.set(address, coordinates)
            return coordinates
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    private func geocoderLocation(for address: String) async throws -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            guard let error = error as? CLError, error.code == .geocodeFoundNoResult else {
                throw error
            }
            print("Geocode found no result for \"\(address)\"")
            return nil
        }
    }

    private func searchLocation(for address: String, in geocoderLocation: CLLocationCoordinate2D?) async throws -> CLLocationCoordinate2D? {
        let searchDistance: CLLocationDistance = 10000
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = address

        if let geocoderLocation {
            searchRequest.region = MKCoordinateRegion(
                center: geocoderLocation,
                latitudinalMeters: searchDistance,
                longitudinalMeters: searchDistance
            )
        }
        do {
            let results = try await MKLocalSearch(request: searchRequest).start()
            return results.mapItems.first?.placemark.coordinate
        } catch {
            guard let error = error as? MKError, error.code == .placemarkNotFound else {
                throw error
            }
            print("Placemark not found for \"\(address)\"")
            return nil
        }
    }
}
