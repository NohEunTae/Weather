//
//  TodayDetailWeatherTableViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class TodayDetailWeatherTableViewCell: UITableViewCell {
    
    enum DetailType: Int {
        case sunriseAndSunset               = 0
        case precipProbabilityAndHumidity   = 1
        case windAndApparentTemperatur      = 2
        case precipIntensityAndPressure     = 3
        case visibilityAndUvIndex           = 4
    }
    
    @IBOutlet weak var leftTitle: UILabel!
    @IBOutlet weak var leftContent: UILabel!
    @IBOutlet weak var rightTitle: UILabel!
    @IBOutlet weak var rightContent: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with detailCity: DetailCity, detailType: DetailType) {
        switch detailType {
        case .sunriseAndSunset:
            DispatchQueue.main.async {
                self.leftTitle.text = "일출"
                self.rightTitle.text = "일몰"
                self.leftContent.text = Date(timeIntervalSince1970: detailCity.sunrise).toString(timezone: detailCity.timezone, dateFormat: "a h:mm")
                self.rightContent.text = Date(timeIntervalSince1970: detailCity.sunset).toString(timezone: detailCity.timezone, dateFormat: "a h:mm")
                self.setNeedsLayout()
            }
        case .precipProbabilityAndHumidity:
            DispatchQueue.main.async {
                self.leftTitle.text = "비 올 확률"
                self.rightTitle.text = "습도"
                self.leftContent.text = "\(Int(detailCity.precipProbability * 100))%"
                self.rightContent.text = "\(Int(detailCity.humidity * 100))%"
                self.setNeedsLayout()
            }
        case .windAndApparentTemperatur:
            DispatchQueue.main.async {
                self.leftTitle.text = "바람"
                self.rightTitle.text = "체감"
                
                let directions = ["북", "북동", "동", "남동", "남", "남서", "서", "북서"]
                let index = Int((detailCity.windBearing / 45).rounded()) % 8

                self.leftContent.text = "\(directions[index]) \(Int(detailCity.windSpeed))m/s"
                self.rightContent.text = "\(Int(detailCity.apparentTemp.fahrenheitToCelsius()))°"
                self.setNeedsLayout()
            }
        case .precipIntensityAndPressure:
            DispatchQueue.main.async {
                self.leftTitle.text = "강수량"
                self.rightTitle.text = "기압"
                self.leftContent.text = "\(Int(detailCity.precipIntensity * 10))cm"
                self.rightContent.text = "\(Int(detailCity.pressure))hPa"
                self.setNeedsLayout()
            }
        case .visibilityAndUvIndex:
            DispatchQueue.main.async {
                self.leftTitle.text = "가시거리"
                self.rightTitle.text = "자외선 지수"
                self.leftContent.text = String(format: "%.1fkm", arguments: [detailCity.visibility])
                self.rightContent.text = "\(detailCity.uvIndex)"
                self.setNeedsLayout()
            }
            break
        }
    }

}
