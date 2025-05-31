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

    init(_ coordinates: CLLocationCoordinate2D) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

extension CLLocationCoordinate2D {

    init(_ coordinates: Coordinates) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

protocol GeocodeServiceProviding {
    func geocodeLocation(_ location: String) async -> Coordinates?
}

class GeocodeServiceProvider<LocationCache: Cache>: GeocodeServiceProviding
where LocationCache.Key == String, LocationCache.Value == Coordinates? {

    private let geocoder = CLGeocoder()
    private let cache: LocationCache

    init(cache: LocationCache = LRUCache(capacity: 50)) {
        self.cache = cache
    }

    func geocodeLocation(_ location: String) async -> Coordinates? {

        if let coordinates = cache.get(location) {
            print("Cache hit for location: \"\(location)\"")
            return coordinates
        }

        print("Geocoding \"\(location)\"")

        let sanitized = location.replacingOccurrences(of: ["(", ")"], with: " ")

        do {
            let geocoderLocation = try await geocodeAddressString(sanitized)

            let searchLocation = try await naturalLanguageSearch(sanitized, in: geocoderLocation)

            guard let result = searchLocation ?? geocoderLocation else {
                cache.set(location, nil)
                return nil
            }

            let coordinates = Coordinates(result)
            cache.set(location, coordinates)
            return coordinates
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    private func geocodeAddressString(_ address: String) async throws -> CLLocationCoordinate2D? {
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

    private func naturalLanguageSearch(_ location: String, in geocoderLocation: CLLocationCoordinate2D?) async throws -> CLLocationCoordinate2D? {
        let searchDistance: CLLocationDistance = 10000
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = location

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
            print("Placemark not found for \"\(location)\"")
            return nil
        }
    }
}
