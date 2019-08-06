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
        Network.request(urlPath: "http://openweathermap.org/img/wn/\(conciseCity.weatherIcon)@2x.png") { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async { [weak self] in
                    self?.weatherIcon.image = UIImage(data: data)
                }
            case .failed:
                break
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.time.text = Date().toString(timezone: conciseCity.timezone, dateFormat: "a h:mm")
            self.cityName.text = conciseCity.name
            self.temperature.text = "\(Int(conciseCity.temp.kalvinToCelsius()))°"
            self.gpsContainer.isHidden = true
            self.setNeedsLayout()
        }
    }
    
    func showUserGps() {
        DispatchQueue.main.async { [weak self] in
            self?.gpsContainer.isHidden = false
            self?.setNeedsLayout()
        }
    }
}
