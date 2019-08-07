//
//  HourlyWeatherCollectionViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class HourlyWeatherCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var precipProbability: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var temp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        precipProbability.isHidden = true
    }
    
    func modifyCell(with hourlyWeather: HourlyWeather, timezone: TimeZone) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.time.text = Date(timeIntervalSince1970: hourlyWeather.timeInterval).toString(timezone: timezone, dateFormat: "a h시")
            if let precipProbability = hourlyWeather.precipProbability {
                self.precipProbability.isHidden = false
                self.precipProbability.text = "\(Int(precipProbability * 100))%"
            }
            
            self.weatherIcon.image = UIImage(named: hourlyWeather.weatherIcon)!
            self.temp.text = "\(Int(hourlyWeather.temp.fahrenheitToCelsius()))°"
            
            self.setNeedsLayout()
        }
    }
}
