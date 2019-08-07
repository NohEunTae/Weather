//
//  City.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

protocol City {
    var cityID: Int { get }
    var name: String { get }
    var timezone: TimeZone { get }
}
