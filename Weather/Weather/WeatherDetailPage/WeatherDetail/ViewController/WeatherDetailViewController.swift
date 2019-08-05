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
    
    private var detailCity: DetailCity? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.titleView.update(subtitle: Date().toString(timezone: self.city.timezone, dateFormat: "a h:mm"))
            }
        }
    }
    weak var delegate: WeatherDetailViewControllerDelegate? = nil
    
    var pageIndex = Int()
    
    init (city: ConciseCity, index: Int) {
        self.darkSkyKey = "d5a6a5386aeaba96fe2d617545464209"
        self.urlPath = String(format: "https://api.darksky.net/forecast/\(self.darkSkyKey)/%lf,%lf?lang=ko", city.coordinate.latitude, city.coordinate.longitude)
        self.city = city
        self.pageIndex = index
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
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.stopClock()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.clock.startClock()
            self?.fetchData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self)
        clock.stopClock()
    }
    
    func setupNavigationBarItems() {
        self.navigationItem.titleView = titleView
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

        self.weatherDetailTableView.delegate = self
        self.weatherDetailTableView.dataSource = self
        self.weatherDetailTableView.register(todayWeatherTableViewCell, forCellReuseIdentifier: "TodayWeatherTableViewCell")
        self.weatherDetailTableView.register(hourlyWeatherTableViewCell, forCellReuseIdentifier: "HourlyWeatherTableViewCell")
        self.weatherDetailTableView.register(dailyWeatherTableViewCell, forCellReuseIdentifier: "DailyWeatherTableViewCell")
        self.weatherDetailTableView.register(weatherDescriptionTableViewCell, forCellReuseIdentifier: "WeatherDescriptionTableViewCell")
        self.weatherDetailTableView.register(todayDetailWeatherTableViewCell, forCellReuseIdentifier: "TodayDetailWeatherTableViewCell")
    }
    
    func fetchData() {
        Network.request(urlPath: urlPath) { [unowned self] (result, data) in
            guard let validData = data else {
                print("invalid data")
                return
            }
            
            switch result {
            case .success:
                self.jsonParser.delegate = self
                self.jsonParser.startParsing(data: validData, parsingType: .detail, conciseCity: self.city)
            case .failed:
                print("failed")
            }
        }
    }
    
    @objc func listButtonClicked(sender: UIButton) {
        self.delegate?.listButtonClicked()
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
            self.detailCity = result as? DetailCity
            guard self.detailCity != nil else { return }
            DispatchQueue.main.async {
                self.weatherDetailTableView.reloadData()
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
