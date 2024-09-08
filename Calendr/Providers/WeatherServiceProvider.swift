//
//  WeatherServiceProvider.swift
//  Calendr
//
//  Created by Paker on 08/09/2024.
//

import Foundation
import WeatherKit

struct Weather {

    struct Day {
        let date: Date
        let highTemperature: Measurement<UnitTemperature>
        let lowTemperature: Measurement<UnitTemperature>
        let symbolName: String
    }

    struct Hour {
        let date: Date
        let temperature: Measurement<UnitTemperature>
        let symbolName: String
    }

    let day: Day
    let hours: [Hour]
    fileprivate let expirationDate: Date
}

@available(macOS 13.0, *)
private extension Weather.Day {

    init(_ day: DayWeather) {
        self.init(
            date: day.date,
            highTemperature: day.highTemperature,
            lowTemperature: day.lowTemperature,
            symbolName: day.symbolName
        )
    }
}

@available(macOS 13.0, *)
private extension Weather.Hour {

    init(_ hour: HourWeather) {
        self.init(
            date: hour.date,
            temperature: hour.temperature,
            symbolName: hour.symbolName
        )
    }
}

@available(macOS 13.0, *)
private extension Array where Element == Weather.Hour {

    init(_ hours: any Sequence<HourWeather>) {
        self.init(hours.map(Element.init))
    }
}

protocol WeatherServiceProviding {

    func weather(for coordinates: Coordinates, start: Date, end: Date) async -> Weather?
}

class WeatherServiceProvider: WeatherServiceProviding {

    func weather(for coordinates: Coordinates, start: Date, end: Date) async -> Weather? { nil }
}

extension WeatherServiceProviding {

    func weather(for coordinates: Coordinates, on date: Date) async -> Weather? {

        await weather(for: coordinates, start: date, end: date)
    }
}

private struct WeatherCacheKey: Hashable {
    let coordinates: Coordinates
    let start: Date
    let end: Date
}

extension WeatherCacheKey: CustomStringConvertible {

    var description: String {
        let start = start.formatted(date: .abbreviated, time: .shortened)
        let end = end.formatted(date: .abbreviated, time: .shortened)
        return "\(coordinates) from \"\(start)\" to \"\(end)\""
    }
}

@available(macOS 13.0, *)
private class AppWeatherServiceProvider<WeatherCache: Cache>: WeatherServiceProvider
where WeatherCache.Key == WeatherCacheKey, WeatherCache.Value == Weather {

    private let dateProvider: DateProviding
    private let cache: WeatherCache

    init(dateProvider: DateProviding, cache: WeatherCache = LRUCache(capacity: 50)) {
        self.dateProvider = dateProvider
        self.cache = cache
    }

    override func weather(for coordinates: Coordinates, start: Date, end: Date) async -> Weather? {

        let cacheKey = WeatherCacheKey(coordinates: coordinates, start: start, end: end)

        if let weather = cache.get(cacheKey) {
            if dateProvider.now < weather.expirationDate {
                print("Cache hit for weather in: \(cacheKey)")
                return weather
            } else {
                print("Cache expired for weather in: \(cacheKey)")
                cache.remove(cacheKey)
            }
        }

        do {
            let (daily, hourly) = try await WeatherService.shared.weather(
                for: .init(latitude: coordinates.latitude, longitude: coordinates.longitude),
                including: .daily(startDate: start, endDate: end + 1), .hourly(startDate: start, endDate: end + 60 * 60)
            )

            guard let day = daily.first else { return nil }

            let weather = Weather(
                day: .init(day),
                hours: .init(hourly.forecast),
                expirationDate: min(daily.metadata.expirationDate, hourly.metadata.expirationDate)
            )
            cache.set(cacheKey, weather)
            print(weather)

            return weather
        } catch {
            guard let error = error as? WeatherError else {
                print(error.localizedDescription)
                return nil
            }
            if let errorDescription = error.errorDescription {
                print("errorDescription", errorDescription)
            }
            if let failureReason = error.failureReason {
                print("failureReason", failureReason)
            }
            if let recoverySuggestion = error.recoverySuggestion {
                print("recoverySuggestion", recoverySuggestion)
            }
            return nil
        }
    }
}

extension WeatherServiceProviding where Self == WeatherServiceProvider {

    static func make(dateProvider: DateProviding) -> Self {

        if #available(macOS 13.0, *) {
            return AppWeatherServiceProvider(dateProvider: dateProvider)
        } else {
            return WeatherServiceProvider()
        }
    }
}
