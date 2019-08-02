//
//  Date+Extension.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

extension Date {
    func toString(timezone: TimeZone, dateFormat format: String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.amSymbol = "오전"
        dateFormatter.pmSymbol = "오후"
        dateFormatter.timeZone = timezone
        dateFormatter.locale = Locale.autoupdatingCurrent
        return dateFormatter.string(from: self)
    }
}
