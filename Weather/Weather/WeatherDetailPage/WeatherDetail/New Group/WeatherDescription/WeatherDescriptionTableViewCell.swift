//
//  WeatherDescriptionTableViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class WeatherDescriptionTableViewCell: UITableViewCell {
    @IBOutlet weak var weatherDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with detailCity: DetailCity) {
        DispatchQueue.main.async {
            self.weatherDescription.text = "오늘: 현재 날씨 \(detailCity.summary). 현재 기온은 \(Int(detailCity.temp.fahrenheitToCelsius()))°이며 최고 기온은 \(Int(detailCity.tempMax.fahrenheitToCelsius()))°입니다."
            self.setNeedsLayout()
        }
    }
}
