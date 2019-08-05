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
    @IBOutlet weak var weatherTableView: UITableView!
    private let openWeatherKey: String = "ec6cbd9a65c144c9cc430169aa554e3d"
    private var jsonParser = JsonParser()
    private var conciseCites: [ConciseCity] = []
    private let clock: Clock = Clock()

    init() {
        super.init(nibName: "WeatherListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupTableViewDataSource()
        
        clock.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clock.startClock()
        weatherTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clock.stopClock()
    }
    
    func setupTableView() {
        let nibCell = UINib(nibName: "WeatherTableViewCell", bundle: nil)
        self.weatherTableView.delegate = self
        self.weatherTableView.dataSource = self        
        self.weatherTableView.register(nibCell, forCellReuseIdentifier: "WeatherTableViewCell")
    }
    
    @objc func addTapped(sender: UIBarButtonItem) {
        let searchCityViewController = SearchCityViewController()
        searchCityViewController.delegate = self
        self.navigationController?.pushViewController(searchCityViewController, animated: true)
    }
    
    func setupTableViewDataSource() {
        if let data = UserDefaults.standard.value(forKey: "city") as? Data {
            if let cities = try? PropertyListDecoder().decode(Array<DefaultCity>.self, from: data) {
                var totalIds: String = ""
                for city in cities {
                    totalIds += "\(city.cityID),"
                }
                totalIds.removeLast()
                let urlPath = "http://api.openweathermap.org/data/2.5/group?id=\(totalIds)&units=metric&appId=\(self.openWeatherKey)"
            
                Network.request(urlPath: urlPath) { (result, data) in
                    guard let validData = data else {
                        print("invalid data")
                        return
                    }
                    
                    switch result {
                    case .success:
                        self.jsonParser.delegate = self
                        self.jsonParser.startParsing(data: validData, parsingType: .cities, defaultCities: cities)
                    case .failed:
                        print("failed")
                    }
                }
            }
        }
    }
}

extension WeatherListViewController: SearchResultViewControllerDelegate {
    func searchDidFinished(item: MKMapItem) {
        let urlPath = String(format: "https://api.openweathermap.org/data/2.5/weather?lat=%lf&lon=%lf&appid=\(self.openWeatherKey)", item.placemark.coordinate.latitude, item.placemark.coordinate.longitude)
        Network.request(urlPath: urlPath) { (result, data) in
            guard let validData = data else {
                print("invalid data")
                return
            }
            
            switch result {
            case .success:
                self.jsonParser.delegate = self
                self.jsonParser.startParsing(data: validData, parsingType: .city, cityName: item.placemark.name!)
            case .failed:
                print("failed")
            }
        }
    }
}

extension WeatherListViewController: JsonParserDelegate {
    func parsingDidFinished<T>(result: T, parsingType: JsonParser.ParsingType) {
        switch parsingType {
        case .city:
            let conciseCity = result as! ConciseCity
            conciseCites.append(conciseCity)
            DispatchQueue.main.async {
                self.weatherTableView.reloadData()
            }
            
            if let data = UserDefaults.standard.value(forKey: "city") as? Data {
                if var cities = try? PropertyListDecoder().decode(Array<DefaultCity>.self, from: data) {
                    let city = DefaultCity(city: conciseCity)
                    cities.append(city)
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(cities), forKey: "city")
                }
            } else {
                let city = DefaultCity(city: conciseCity)
                let cities: [DefaultCity] = [city, ]
                UserDefaults.standard.set(try? PropertyListEncoder().encode(cities), forKey: "city")
            }
        case .cities:
            let cities = result as! [ConciseCity]
            self.conciseCites = cities
            DispatchQueue.main.async {
                self.weatherTableView.reloadData()
            }
        default:
            break
        }
    }
}

extension WeatherListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailPageViewController = WeatherDetailPageViewController(startIndex: indexPath.row, cities: conciseCites)
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(detailPageViewController, animated: true)
        }
    }
}

extension WeatherListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if let data = UserDefaults.standard.value(forKey: "city") as? Data {
                if var cities = try? PropertyListDecoder().decode(Array<DefaultCity>.self, from: data) {
                    cities.remove(at: indexPath.row)
                    conciseCites.remove(at: indexPath.row)
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(cities), forKey: "city")
                    DispatchQueue.main.async {
                        self.weatherTableView.reloadData()
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conciseCites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableViewCell", for: indexPath) as! WeatherTableViewCell
        cell.modifyCell(with: self.conciseCites[indexPath.row])
        return cell
    }
}

extension WeatherListViewController: ClockDelegate {
    func minuteChanged() {
        setupTableViewDataSource()
    }
}
