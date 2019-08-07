//
//  WeatherDetailViewController.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

protocol WeatherDetailViewControllerDelegate: AnyObject {
    func listButtonClicked()
}

class WeatherDetailViewController: UIViewController {
    private let darkSkyKey: String
    private var jsonParser = JsonParser()
    private let urlPath: String
    private let city: ConciseCity
    private let clock: Clock = Clock()
    @IBOutlet weak var weatherDetailTableView: UITableView!
    private let titleView = TitleView()
    weak var delegate: WeatherDetailViewControllerDelegate? = nil
    var pageIndex = Int()
    private var detailCity: DetailCity? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.titleView.update(subtitle: Date().toString(timezone: self.city.timezone, dateFormat: "a h:mm"))
            }
            
            UserDefaults.standard.set(try? PropertyListEncoder().encode(detailCity), forKey: city.name)
        }
    }

    init (city: ConciseCity, index: Int) {
        darkSkyKey = "d5a6a5386aeaba96fe2d617545464209"
        urlPath = String(format: "https://api.darksky.net/forecast/\(darkSkyKey)/%lf,%lf?lang=ko", city.coordinate.latitude, city.coordinate.longitude)
        self.city = city
        pageIndex = index
        super.init(nibName: "WeatherDetailViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        setupTableView()
        clock.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clock.startClock()
        fetchData()
        setupNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        clock.stopClock()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.stopClock()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.startClock()
            self?.fetchData()
        }
    }
    
    func setupNavigationBarItems() {
        let bar:UINavigationBar! =  navigationController?.navigationBar
        bar.backgroundColor = UIColor(red: 31/255, green: 33/255, blue: 36/255, alpha: 1)
        navigationItem.titleView = titleView
        titleView.set(city.name, subtitle: Date().toString(timezone: city.timezone, dateFormat: "a h:mm"))
        let listButton = UIBarButtonItem(image: UIImage(named: "list"), style: .plain, target: self, action: #selector(listButtonClicked))
        self.navigationItem.rightBarButtonItem = listButton
    }
    
    func setupTableView() {
        let todayWeatherTableViewCell = UINib(nibName: "TodayWeatherTableViewCell", bundle: nil)
        let hourlyWeatherTableViewCell = UINib(nibName: "HourlyWeatherTableViewCell", bundle: nil)
        let dailyWeatherTableViewCell = UINib(nibName: "DailyWeatherTableViewCell", bundle: nil)
        let weatherDescriptionTableViewCell = UINib(nibName: "WeatherDescriptionTableViewCell", bundle: nil)
        let todayDetailWeatherTableViewCell = UINib(nibName: "TodayDetailWeatherTableViewCell", bundle: nil)

        weatherDetailTableView.delegate = self
        weatherDetailTableView.dataSource = self
        weatherDetailTableView.register(todayWeatherTableViewCell, forCellReuseIdentifier: "TodayWeatherTableViewCell")
        weatherDetailTableView.register(hourlyWeatherTableViewCell, forCellReuseIdentifier: "HourlyWeatherTableViewCell")
        weatherDetailTableView.register(dailyWeatherTableViewCell, forCellReuseIdentifier: "DailyWeatherTableViewCell")
        weatherDetailTableView.register(weatherDescriptionTableViewCell, forCellReuseIdentifier: "WeatherDescriptionTableViewCell")
        weatherDetailTableView.register(todayDetailWeatherTableViewCell, forCellReuseIdentifier: "TodayDetailWeatherTableViewCell")
    }
    
    func fetchData() {
        Network.request(urlPath: urlPath) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.jsonParser.delegate = self
                self.jsonParser.startParsing(data: data, parsingType: .detail, conciseCity: self.city)
            case .failed(let error):
                if let data = UserDefaults.standard.value(forKey: self.city.name) as? Data {
                    if let city = try? PropertyListDecoder().decode(DetailCity.self, from: data) {
                        self.detailCity = city
                        DispatchQueue.main.async { [weak self] in
                            self?.weatherDetailTableView.reloadData()
                        }
                    }
                } else {
                    self.presentAlert(error.localizedDescription, message: "\(error.code)", completion: nil)
                }
            }
        }
    }
    
    @objc func listButtonClicked(sender: UIButton) {
        delegate?.listButtonClicked()
    }
}

extension WeatherDetailViewController: ClockDelegate {
    func minuteChanged() {
        fetchData()
    }
}

extension WeatherDetailViewController: JsonParserDelegate {
    func parsingDidFinished<T>(result: T, parsingType: JsonParser.ParsingType) {
        switch parsingType {
        case .detail:
            detailCity = result as? DetailCity
            guard detailCity != nil else { return }
            DispatchQueue.main.async { [weak self] in
                self?.weatherDetailTableView.reloadData()
            }
        default:
            break
        }
    }
}

extension WeatherDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard detailCity != nil else { return 0 }

        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .today:
                return 155
            case .hourly:
                return 110
            case .daily:
                return 44
            case .description:
                return 88
            case .detail:
                return 70
            }
        }
        return 0
    }
}

extension WeatherDetailViewController: UITableViewDataSource {
    enum Section: Int {
        case today          = 0
        case hourly         = 1
        case daily          = 2
        case description    = 3
        case detail         = 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let detailCity = detailCity  else { return 0 }
        
        if let section = Section(rawValue: section) {
            switch section {
            case .today:
                return 1
            case .hourly:
                return 1
            case .daily:
                return detailCity.dailyWeathers.count
            case .description:
                return 1
            case .detail:
                return 5
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let detailCity = detailCity  else { return UITableViewCell() }

        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .today:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TodayWeatherTableViewCell", for: indexPath) as! TodayWeatherTableViewCell
                cell.modifyCell(with: detailCity)
                return cell
            case .hourly:
                let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyWeatherTableViewCell", for: indexPath) as! HourlyWeatherTableViewCell
                cell.modifyCell(with: detailCity.hourlyWeathers, timezone: detailCity.timezone)
                return cell
            case .daily:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DailyWeatherTableViewCell", for: indexPath) as! DailyWeatherTableViewCell
                cell.modifyCell(with: detailCity.dailyWeathers[indexPath.row], timezone: detailCity.timezone)
                return cell
            case .description:
                let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherDescriptionTableViewCell", for: indexPath) as! WeatherDescriptionTableViewCell
                cell.modifyCell(with: detailCity)
                return cell
            case .detail:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TodayDetailWeatherTableViewCell", for: indexPath) as! TodayDetailWeatherTableViewCell
                if let detailType = TodayDetailWeatherTableViewCell.DetailType(rawValue: indexPath.row) {
                    cell.modifyCell(with: detailCity, detailType: detailType)
                }
                return cell
            }
        }

        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return detailCity == nil ? 0 : 5
    }
}
