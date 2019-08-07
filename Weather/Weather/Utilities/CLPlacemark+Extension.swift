//
//  CLPlacemark+Extension.swift
//  Weather
//
//  Created by user on 04/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import CoreLocation

extension CLPlacemark {
    func cityName() -> String? {
        if let _ = location {
            if let city = self.administrativeArea, !city.isEmpty {
                return city
            }
        }
        return nil
    }
}
