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
            UserDefaults.standard.set(try? PropertyListEncoder().encode(conciseCities), forKey: "city")
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.weatherTableView.reloadData()
        clock.startClock()
        setupNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clock.stopClock()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.stopClock()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.startClock()
            DispatchQueue.main.async { [weak self] in
                self?.weatherTableView.reloadData()
            }
        }
    }
    
    func setupLocationManager() {
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupTableView() {
        let nibCell = UINib(nibName: "WeatherTableViewCell", bundle: nil)
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
        weatherTableView.register(nibCell, forCellReuseIdentifier: "WeatherTableViewCell")
    }
    
    @objc func addTapped(sender: UIBarButtonItem) {
        let searchCityViewController = SearchCityViewController()
        searchCityViewController.delegate = self
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(searchCityViewController, animated: true)
        }
    }
    
    func setupTableViewDataSource() {
        if let data = UserDefaults.standard.value(forKey: "city") as? Data {
            if var cities = try? PropertyListDecoder().decode(Array<ConciseCity>.self, from: data) {
                if CLLocationManager.locationServicesEnabled(), cities.count == 20 {
                    cities.removeLast()
                }
                self.conciseCities = cities
                fetchData(conciseCities: self.conciseCities)
            }
        }
    }
    
    func updateDataSource() {
        var cities: [ConciseCity] = conciseCities
        if let userCity = userCity {
            if cities.count == 20 {
                cities.removeLast()
            }
            cities.insert(userCity, at: 0)
        }

        fetchData(conciseCities: cities)
    }
    
    func fetchData(conciseCities: [ConciseCity]) {
        guard !conciseCities.isEmpty else { return }
        var totalIds = ""
        for city in conciseCities {
            totalIds += "\(city.cityID),"
        }
        totalIds.removeLast()
        let urlPath = "http://api.openweathermap.org/data/2.5/group?id=\(totalIds)&units=metric&appId=\(self.openWeatherKey)"
        Network.request(urlPath: urlPath) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.jsonParser.delegate = self
                self.jsonParser.startParsing(data: data, parsingType: .cities, conciseCities: conciseCities)
            case .failed(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.conciseCities.count > 0 ? self.weatherTableView.reloadData() : self.presentAlert(error.localizedDescription, message: "\(error.code)", completion: nil)
                }
            }
        }
    }
}

extension WeatherListViewController: SearchResultViewControllerDelegate {
    func searchDidFinished(item: MKMapItem) {
        let urlPath = String(format: "https://api.openweathermap.org/data/2.5/weather?lat=%lf&lon=%lf&appid=\(self.openWeatherKey)", item.placemark.coordinate.latitude, item.placemark.coordinate.longitude)
        Network.request(urlPath: urlPath) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.jsonParser.delegate = self
                self.jsonParser.startParsing(data: data, parsingType: .city, cityName: item.placemark.name!)
            case .failed(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error.localizedDescription, message: "\(error.code)", completion: nil)
                }
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
            delegate?.deleteUserWeather()
            userCity = nil
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                self?.weatherTableView.reloadSections([0], with: .automatic)
            }
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            if userCity == nil {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: { [weak self] (placemarks, error) in
                guard let self = self else { return }
                if error == nil, let placemarks = placemarks, !placemarks.isEmpty {
                    let urlPath = String(format: "https://api.openweathermap.org/data/2.5/weather?lat=%lf&lon=%lf&appid=\(self.openWeatherKey)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                    Network.request(urlPath: urlPath) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let data):
                            self.jsonParser.delegate = self
                            self.jsonParser.startParsing(data: data, parsingType: .userLocation, cityName: placemarks.last!.cityName())
                        case .failed(let error):
                            self.presentAlert(error.localizedDescription, message: "\(error.code)", completion: nil)
                        }
                    }
                }
            })
            locationManager.stopUpdatingLocation()
        }
    }
}

extension WeatherListViewController: JsonParserDelegate {
    private var dataSourceCount: Int {
        let userCount = userCity == nil ? 0 : 1
        return userCount + conciseCities.count
    }

    func parsingDidFinished<T>(result: T, parsingType: JsonParser.ParsingType) {
        switch parsingType {
        case .userLocation:
            if let userCity = result as? ConciseCity {
                self.delegate?.addUserWeather(user: userCity)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.navigationItem.rightBarButtonItem?.isEnabled = self.dataSourceCount >= 19 ? false : true

                    self.userCity = userCity
                    self.weatherTableView.reloadSections([Section.userWeather.rawValue], with: .automatic)
                }
            }
        case .city:
            let conciseCity = result as! ConciseCity
            let isExist = conciseCities.filter { $0.cityID == conciseCity.cityID }
            guard isExist.isEmpty == true else { break }

            let indexPath = IndexPath(row:conciseCities.count, section: Section.savedWeather.rawValue)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem?.isEnabled = self.dataSourceCount >= 19 ? false : true
                self.conciseCities.append(conciseCity)
                self.weatherTableView.insertRows(at: [indexPath], with: .automatic)
            }            
        case .cities:
            var cities = result as! [ConciseCity]
            if conciseCities.count < cities.count, userCity != nil {
                userCity = cities.removeFirst()
            }
            conciseCities = cities
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem?.isEnabled = self.dataSourceCount >= 20 ? false : true
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
                startIndex = userCity == nil ? indexPath.row : indexPath.row + 1
            }
        }
        let detailPageViewController = WeatherDetailPageViewController(startIndex: startIndex, cities: cities)
        delegate = detailPageViewController
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(detailPageViewController, animated: true)
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
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
                cell.modifyCell(with: conciseCities[indexPath.row])
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
