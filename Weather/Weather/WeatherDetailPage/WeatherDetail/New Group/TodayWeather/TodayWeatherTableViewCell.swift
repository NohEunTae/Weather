//
//  TodayWeatherTableViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class TodayWeatherTableViewCell: UITableViewCell {
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var temp: UILabel!
    @IBOutlet weak var day: UILabel!
    @IBOutlet weak var tempMax: UILabel!
    @IBOutlet weak var tempMin: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with detailCity: DetailCity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.weatherIcon.image = UIImage(named: detailCity.weatherIcon)!
            self.summary.text = detailCity.summary
            self.temp.text = "\(Int(detailCity.temp.fahrenheitToCelsius()))°"
            self.day.text = Date().toString(timezone: detailCity.timezone, dateFormat: "EEEE")
            self.tempMax.text = "\(Int(detailCity.tempMax.fahrenheitToCelsius()))"
            self.tempMin.text = "\(Int(detailCity.tempMin.fahrenheitToCelsius()))"
            self.setNeedsLayout()
        }
    }
}
