//
//  DetailCity.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

struct DetailCity: City, Codable {
    let cityID: Int
    let name: String
    let timezone: TimeZone
    
    let summary: String
    
    let hourlyWeathers: [HourlyWeather]
    let dailyWeathers: [DailyWeather]
    
    let temp: Double
    let tempMax: Double
    let tempMin: Double

    let sunrise: TimeInterval
    let sunset: TimeInterval
    let precipProbability: Double
    let humidity: Double
    
    let windSpeed: Double
    let windBearing: Double
    let apparentTemp: Double

    let precipIntensity: Double
    let pressure: Double

    let visibility: Double
    let uvIndex: Int
    
    let weatherIcon: String
}
