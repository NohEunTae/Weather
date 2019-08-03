//
//  HourlyWeatherTableViewCell.swift
//  Weather
//
//  Created by user on 03/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class HourlyWeatherTableViewCell: UITableViewCell {
    @IBOutlet weak var hourlyCollectionView: UICollectionView!
    var hourlyWeathers: [HourlyWeather] = []
    var timezone: TimeZone!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.hourlyCollectionView.delegate = self
        self.hourlyCollectionView.dataSource = self
        
        let nibCell = UINib(nibName: "HourlyWeatherCollectionViewCell", bundle: nil)
        self.hourlyCollectionView.register(nibCell, forCellWithReuseIdentifier: "HourlyWeatherCollectionViewCell")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func modifyCell(with hourlyWeathers: [HourlyWeather], timezone: TimeZone) {
        self.hourlyWeathers = hourlyWeathers
        self.timezone = timezone
    }
}

extension HourlyWeatherTableViewCell: UICollectionViewDelegate {}

extension HourlyWeatherTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyWeathers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyWeatherCollectionViewCell", for: indexPath) as! HourlyWeatherCollectionViewCell
        cell.modifyCell(with: hourlyWeathers[indexPath.row], timezone: timezone)
        return cell
    }
}
