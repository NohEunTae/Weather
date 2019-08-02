//
//  DefaultCity.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

struct DefaultCity: City, Codable {
    
    let cityID: Int
    let name: String
    let timezone: TimeZone
    
    init(city: City) {
        cityID = city.cityID
        name = city.name
        timezone = city.timezone
    }
}
