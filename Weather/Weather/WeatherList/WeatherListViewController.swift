//
//  WeatherListViewController.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class WeatherListViewController: UIViewController {
    @IBOutlet weak var weatherTableView: UITableView!
    private let openWeatherKey: String = "ec6cbd9a65c144c9cc430169aa554e3d"
    private var jsonParser = JsonParser()
    private var conciseCities: [ConciseCity] = [] {
        didSet {
            let defaultCities = conciseCities.map { DefaultCity(city: $0)}
            UserDefaults.standard.set(try? PropertyListEncoder().encode(defaultCities), forKey: "city")
        }
    }
    private let clock: Clock = Clock()
    private let locationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()
    
    private var userCity: ConciseCity? = nil
    
    init() {
        super.init(nibName: "WeatherListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupLocationManager()
        clock.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clock.startClock()
        conciseCities.isEmpty ? setupTableViewDataSource() : updateDataSource()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.stopClock()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.startClock()
            self?.updateDataSource()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        clock.stopClock()
    }
    
    func setupLocationManager() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
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
                self.fetchData(defaultCities: cities)
            }
        }
    }
    
    func updateDataSource() {
        let defaultCities: [DefaultCity] = conciseCities.map { DefaultCity(city: $0 as City) }
        self.fetchData(defaultCities: defaultCities)
    }
    
    func fetchData(defaultCities: [DefaultCity]) {
        var totalIds = ""
        for city in defaultCities {
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
                self.jsonParser.startParsing(data: validData, parsingType: .cities, defaultCities: defaultCities)
            case .failed:
                print("failed")
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

extension WeatherListViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
                if error == nil, let placemarks = placemarks, !placemarks.isEmpty {
                    let urlPath = String(format: "https://api.openweathermap.org/data/2.5/weather?lat=%lf&lon=%lf&appid=\(self.openWeatherKey)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                    Network.request(urlPath: urlPath) { (result, data) in
                        guard let validData = data else {
                            print("invalid data")
                            return
                        }
                        switch result {
                        case .success:
                            self.jsonParser.delegate = self
                            self.jsonParser.startParsing(data: validData, parsingType: .userLocation, cityName: placemarks.last!.cityName())
                        case .failed:
                            print("failed")
                        }
                    }
                }
            })
            locationManager.stopUpdatingLocation()
        }
    }
}

extension WeatherListViewController: JsonParserDelegate {
    func parsingDidFinished<T>(result: T, parsingType: JsonParser.ParsingType) {
        switch parsingType {
        case .userLocation:
            self.userCity = result as? ConciseCity
            if let _ = userCity {
                DispatchQueue.main.async {
                    if self.conciseCities.count >= 19 {
                        if self.conciseCities.count >= 20 {
                            self.conciseCities.removeLast()
                        }
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    }
                    self.weatherTableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .fade)
                }
            }
        case .city:
            let conciseCity = result as! ConciseCity
            let isExist = conciseCities.filter { $0.cityID == conciseCity.cityID }
            guard isExist.isEmpty == true else { break }
            conciseCities.append(conciseCity)
            DispatchQueue.main.async {
                if self.conciseCities.count == 20 || (self.conciseCities.count == 19 && self.userCity != nil) {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                self.weatherTableView.reloadData()
            }            
        case .cities:
            let cities = result as! [ConciseCity]
            self.conciseCities = cities
            
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
        var cities: [ConciseCity] = []
        if let userCity = userCity {
            cities.append(userCity)
        }
        cities.append(contentsOf: conciseCities)
        let detailPageViewController = WeatherDetailPageViewController(startIndex: indexPath.row, cities: cities)
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(detailPageViewController, animated: true)
        }
    }
}

extension WeatherListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if userCity != nil, indexPath.row == 0 {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let removeIndex = userCity == nil ? indexPath.row : indexPath.row - 1
            conciseCities.remove(at: removeIndex)
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCity == nil ? conciseCities.count : conciseCities.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableViewCell", for: indexPath) as! WeatherTableViewCell
        if let userCity = userCity {
            if indexPath.row == 0 {
                cell.modifyCell(with: userCity)
                cell.showUserGps()
                return cell
            }
            cell.modifyCell(with: self.conciseCities[indexPath.row - 1])
            return cell
        }
        cell.modifyCell(with: self.conciseCities[indexPath.row])
        return cell
    }
}

extension WeatherListViewController: ClockDelegate {
    func minuteChanged() {
        updateDataSource()
    }
}
