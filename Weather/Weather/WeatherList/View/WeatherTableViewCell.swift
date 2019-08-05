//
//  WeatherTableViewCell.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class WeatherTableViewCell: UITableViewCell {
    
    @IBOutlet weak var gpsContainer: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        gpsContainer.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with conciseCity: ConciseCity) {
        let url = URL(string: "http://openweathermap.org/img/wn/\(conciseCity.weatherIcon)@2x.png")
        if let url = url {
            self.downloadImage(from: url, completion: { [weak self] image in
                if let image = image {
                    DispatchQueue.main.async {
                        self?.weatherIcon.image = image
                    }
                }
            })
        }

        DispatchQueue.main.async {
            self.time.text = Date().toString(timezone: conciseCity.timezone, dateFormat: "a h:mm")
            self.cityName.text = conciseCity.name
            self.temperature.text = "\(Int(conciseCity.temp.kalvinToCelsius()))°"
            self.gpsContainer.isHidden = true
            self.setNeedsLayout()
        }
    }
    
    func showUserGps() {
        DispatchQueue.main.async {
            self.gpsContainer.isHidden = false
            self.setNeedsLayout()
        }
    }
}
