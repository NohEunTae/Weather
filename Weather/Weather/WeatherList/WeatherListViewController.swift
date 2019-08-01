//
//  WeatherListViewController.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import MapKit

class WeatherListViewController: UIViewController {
    init() {
        super.init(nibName: "WeatherListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    @objc func addTapped(sender: UIBarButtonItem) {
        let searchCityViewController = SearchCityViewController()
        searchCityViewController.delegate = self
        self.navigationController?.pushViewController(searchCityViewController, animated: true)
    }
}

extension WeatherListViewController: SearchResultTableViewControllerDelegate {
    func searchDidFinished(item: MKMapItem) {
        print(item.placemark.locality)
    }
}
