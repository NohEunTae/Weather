//
//  Double+Extension.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

extension Double {
    func kalvinToCelsius() -> Double {
        return self - 273.15
    }
    
    func celsiusToKalvin() -> Double {
        return self + 273.15
    }
    
    func fahrenheitToCelsius() -> Double {
        return (self - 32) * 5 / 9
    }
}
