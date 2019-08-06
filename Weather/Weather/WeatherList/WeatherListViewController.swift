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

protocol WeatherListViewControllerDelegate: AnyObject {
    func addUserWeather(user: ConciseCity)
    func deleteUserWeather()
}

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
    
    private var userCity: ConciseCity? = nil
    private weak var delegate: WeatherListViewControllerDelegate? = nil
    
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
        setupLocationManager()
        clock.delegate = self
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 32/255, green: 32/255, blue: 36/255, alpha: 1)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
        DispatchQueue.main.async {
            self.weatherTableView.reloadData()
        }
        clock.startClock()
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.stopClock()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.startClock()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clock.stopClock()
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    func setupLocationManager() {
        self.locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.locationServicesEnabled() {
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
            if var cities = try? PropertyListDecoder().decode(Array<DefaultCity>.self, from: data) {
                if CLLocationManager.locationServicesEnabled(), cities.count == 20 {
                    cities.removeLast()
                }
                self.fetchData(defaultCities: cities)
            }
        }
    }
    
    func updateDataSource() {
        var cities: [ConciseCity] = conciseCities
        
        if let userCity = userCity {
            if conciseCities.count == 20 {
                conciseCities.removeLast()
            }
            cities = conciseCities
            cities.insert(userCity, at: 0)
        }

        let defaultCities: [DefaultCity] = cities.map { DefaultCity(city: $0 as City) }
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            fallthrough
        case.restricted:
            fallthrough
        case .denied:
            self.delegate?.deleteUserWeather()
            self.userCity = nil
            self.weatherTableView.reloadSections([0], with: .automatic)
            if !self.conciseCities.isEmpty { self.updateDataSource() }
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            if self.userCity == nil {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
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
            if let userCity = result as? ConciseCity {
                self.delegate?.addUserWeather(user: userCity)
                DispatchQueue.main.async {
                    if self.conciseCities.count >= 19 {
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    }
                    self.userCity = userCity
                    self.weatherTableView.reloadSections([Section.userWeather.rawValue], with: .fade)
                }
            }
        case .city:
            let conciseCity = result as! ConciseCity
            let isExist = conciseCities.filter { $0.cityID == conciseCity.cityID }
            guard isExist.isEmpty == true else { break }
            conciseCities.append(conciseCity)
            let indexPath = IndexPath(row:conciseCities.count - 1, section: Section.savedWeather.rawValue)
            
            DispatchQueue.main.async {
                if self.conciseCities.count == 20 || (self.conciseCities.count == 19 && self.userCity != nil) {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                self.weatherTableView.insertRows(at: [indexPath], with: .automatic)
            }            
        case .cities:
            let cities = result as! [ConciseCity]
            if cities.count > conciseCities.count, userCity != nil {
                self.userCity = cities.first!
                for i in 1..<cities.count {
                    self.conciseCities[i - 1] = cities[i]
                }
            } else {
                self.conciseCities = cities
            }
            
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
        var startIndex: Int = Int()
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .userWeather:
                startIndex = 0
            case .savedWeather:
                startIndex = self.userCity == nil ? indexPath.row : indexPath.row + 1
            }
        }
        let detailPageViewController = WeatherDetailPageViewController(startIndex: startIndex, cities: cities)
        self.delegate = detailPageViewController
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(detailPageViewController, animated: true)
        }
    }
}

extension WeatherListViewController: UITableViewDataSource {
    enum Section: Int {
        case userWeather   = 0
        case savedWeather  = 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .userWeather:
                return false
            case .savedWeather:
                return true
            }
        }
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            conciseCities.remove(at: indexPath.row)
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = Section(rawValue: section) {
            switch section {
            case .userWeather:
                return userCity == nil ? 0 : 1
            case .savedWeather:
                return conciseCities.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableViewCell", for: indexPath) as! WeatherTableViewCell
        
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .userWeather:
                guard let userCity = userCity else { return cell }
                cell.modifyCell(with: userCity)
                cell.showUserGps()
                return cell
            case .savedWeather:
                cell.modifyCell(with: self.conciseCities[indexPath.row])
                return cell
            }
        }
        return cell
    }
}

extension WeatherListViewController: ClockDelegate {
    func minuteChanged() {
        updateDataSource()
    }
}
