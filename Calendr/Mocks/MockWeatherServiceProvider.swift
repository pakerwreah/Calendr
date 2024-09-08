//
//  MockWeatherServiceProvider.swift
//  Calendr
//
//  Created by Paker on 08/09/2024.
//

import Foundation

class MockWeatherServiceProvider: WeatherServiceProviding {
    
    func weather(for coordinates: Coordinates, start: Date, end: Date) async -> Weather? { nil }
}
