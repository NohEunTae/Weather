//
//  HourlyWeather.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

struct HourlyWeather: Codable {
    let timeInterval: TimeInterval
    let precipProbability: Double?
    let weatherIcon: String
    let temp: Double
}
