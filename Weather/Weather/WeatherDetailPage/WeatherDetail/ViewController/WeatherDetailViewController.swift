//
//  WeatherDetailViewController.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class WeatherDetailViewController: UIViewController {

    private let darkSkyKey = "d5a6a5386aeaba96fe2d617545464209"
    private let city: ConciseCity
    private let jsonParser = JsonParser()
    var pageIndex = Int()
    
    init (city: ConciseCity, index: Int) {
        self.city = city
        self.pageIndex = index
        super.init(nibName: "WeatherDetailViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
