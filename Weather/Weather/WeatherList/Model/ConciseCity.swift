//
//  ConciseCity.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

struct ConciseCity: City {
    let name: String
    let timezone: TimeZone
    let temp: Double
    let weatherIcon: String
    let cityID: Int
    let coordinate: Coordinate
}
