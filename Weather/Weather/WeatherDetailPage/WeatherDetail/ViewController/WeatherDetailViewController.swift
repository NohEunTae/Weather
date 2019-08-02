//
//  WeatherDetailViewController.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

protocol WeatherDetailViewControllerDelegate: AnyObject {
    func viewDidLoadCalled(_ index: Int)
    func scrollDown()
    func scrollUp()
}

class WeatherDetailViewController: UIViewController {

    private let darkSkyKey: String
    private let jsonParser = JsonParser()
    private let urlPath: String
    var pageIndex = Int()
    weak var delegate: WeatherDetailViewControllerDelegate? = nil
    
    init (city: ConciseCity, index: Int) {
        self.darkSkyKey = "d5a6a5386aeaba96fe2d617545464209"
        self.urlPath = String(format: "https://api.darksky.net/forecast/\(self.darkSkyKey)/%lf,%lf?lang=ko", city.coordinate.latitude, city.coordinate.longitude)
        self.pageIndex = index
        super.init(nibName: "WeatherDetailViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate?.viewDidLoadCalled(self.pageIndex)
    }
}
