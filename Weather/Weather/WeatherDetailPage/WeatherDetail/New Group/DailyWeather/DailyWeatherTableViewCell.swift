//
//  DailyWeatherTableViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class DailyWeatherTableViewCell: UITableViewCell {
    @IBOutlet weak var day: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var tempMax: UILabel!
    @IBOutlet weak var tempMin: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with dailyWeather: DailyWeather, timezone: TimeZone) {
        DispatchQueue.main.async { [weak self] in
            self?.day.text = Date(timeIntervalSince1970: dailyWeather.timeInterval).toString(timezone: timezone, dateFormat: "EEEE")
            self?.weatherIcon.image = UIImage(named: dailyWeather.weatherIcon)!
            self?.tempMax.text = "\(Int(dailyWeather.tempMax.fahrenheitToCelsius()))"
            self?.tempMin.text = "\(Int(dailyWeather.tempMin.fahrenheitToCelsius()))"
            self?.setNeedsLayout()
        }
    }
}
