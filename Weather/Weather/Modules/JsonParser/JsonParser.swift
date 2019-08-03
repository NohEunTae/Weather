//
//  JsonParser.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

protocol JsonParserDelegate {
    func parsingDidFinished<T>(result: T, parsingType: JsonParser.ParsingType)
}

struct JsonParser {
    enum ParsingType {
        case city
        case cities
        case detail
    }
    
    var delegate: JsonParserDelegate? = nil
    
    func startParsing(data: Data, parsingType: ParsingType, cityName: String? = nil, defaultCities: [DefaultCity]? = nil, conciseCity: ConciseCity? = nil) {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        switch parsingType {
        case .city:
            guard let validCityName = cityName else { return }
            parsingCity(json: json, cityName: validCityName)
        case .cities:
            guard let validCities = defaultCities else { return }
            parsingCities(json: json, defaultCities: validCities)
        case .detail:
            guard let validCity = conciseCity else { return }
            parsingDetailCity(json: json, conciseCity: validCity)
        }
    }
    
    private func parsingCity(json: [String : Any], cityName: String) {
        let timezoneValue = json["timezone"] as? Int
        
        let weather = json["weather"] as? [[String : Any]]
        guard let validWeather = weather else { return }
        let weatherIcon = validWeather.first!["icon"] as? String
        
        let main = json["main"] as? [String : Any]
        guard let validMain = main else { return }
        let temp = validMain["temp"] as? Double
        
        let coord = json["coord"] as? [String: Any]
        guard let validCoord = coord else { return }
        
        let lat = validCoord["lat"] as? Double
        let lon = validCoord["lon"] as? Double
        
        let cityID = json["id"] as? Int
        if let timezoneValue = timezoneValue, let timezone = TimeZone(secondsFromGMT: timezoneValue), let temp = temp, let weatherIcon = weatherIcon, let cityID = cityID, let lat = lat, let lon = lon {
            let coordinate = Coordinate(latitude: lat, longitude: lon)
            let conciseCity = ConciseCity(name: cityName, timezone: timezone, temp: temp, weatherIcon: weatherIcon, cityID: cityID, coordinate: coordinate)
            delegate?.parsingDidFinished(result: conciseCity, parsingType: .city)
        }
    }
    
    private func parsingCities(json: [String: Any], defaultCities: [DefaultCity]) {
        var cities: [ConciseCity] = []
        let list = json["list"] as? [[String: Any]]
        guard let validList = list else { return }
        
        for i in 0..<defaultCities.count {
            let cityName = defaultCities[i].name
            let cityID = defaultCities[i].cityID
            let timezone = defaultCities[i].timezone
            
            let weather = validList[i]["weather"] as? [[String : Any]]
            guard let validWeather = weather else { return }
            let weatherIcon = validWeather.first!["icon"] as? String
            
            let main = validList[i]["main"] as? [String : Any]
            guard let validMain = main else { return }
            let temp = validMain["temp"] as? Double
            let coord = validList[i]["coord"] as? [String: Any]
            guard let validCoord = coord else { return }
            
            let lat = validCoord["lat"] as? Double
            let lon = validCoord["lon"] as? Double
            if let temp = temp, let weatherIcon = weatherIcon, let lat = lat, let lon = lon {
                let coordinate = Coordinate(latitude: lat, longitude: lon)
                let conciseCity = ConciseCity(name: cityName, timezone: timezone, temp: temp.celsiusToKalvin(), weatherIcon: weatherIcon, cityID: cityID, coordinate: coordinate)
                cities.append(conciseCity)
            }
        }        
        delegate?.parsingDidFinished(result: cities, parsingType: .cities)
    }

    private func parsingDetailCity(json: [String: Any], conciseCity: ConciseCity) {
        let cityID = conciseCity.cityID
        let name = conciseCity.name
        let timezone = conciseCity.timezone
        
        // current process
        let currently = json["currently"] as? [String: Any]
        guard let validCurrently = currently else { return }
        
        let summary = validCurrently["summary"] as? String
        guard let validSummary = summary else { return }
        
        let temp = validCurrently["temperature"] as? Double
        guard let validTemp = temp else { return }
        
        let precipProbability = validCurrently["precipProbability"] as? Double
        guard let validPrecipProbability = precipProbability else { return }
        
        let humidity = validCurrently["humidity"] as? Double
        guard let validHumidity = humidity else { return }

        let windSpeed = validCurrently["windSpeed"] as? Double
        guard let validWindSpeed = windSpeed else { return }

        
        let windBearing = validCurrently["windBearing"] as? Double
        guard let validWindBearing = windBearing else { return }
 
        let apparentTemp = validCurrently["apparentTemperature"] as? Double
        guard let validApparentTemp = apparentTemp else { return }

        let precipIntensity = validCurrently["precipIntensity"] as? Double
        guard let validPrecipIntensity = precipIntensity else { return }

        
        let pressure = validCurrently["pressure"] as? Double
        guard let validPressure = pressure else { return }
        
        let visibility = validCurrently["visibility"] as? Double
        guard let validVisibility = visibility else { return }

        let uvIndex = validCurrently["uvIndex"] as? Int
        guard let validUvIndex = uvIndex else { return }

        let weatherIcon = validCurrently["icon"] as? String
        guard let validWeatherIcon = weatherIcon else { return }
        
        // hourly process
        let hourly = json["hourly"] as? [String: Any]
        
        guard let validHourly = hourly else { return }
        let hourlyDatas = validHourly["data"] as? [[String: Any]]
        

        guard let validHourlyDatas = hourlyDatas else { return }
        
        var hourlyWeathers: [HourlyWeather] = []
        for hourlyData in validHourlyDatas {
            let time = hourlyData["time"] as? Int
            guard let validTime = time else { return }
            
            let timeInterval = TimeInterval(exactly: validTime)!
            //timeInterval

            var precipProbability: Double? = hourlyData["precipProbability"] as? Double
            if precipProbability != nil, precipProbability! == 0 { precipProbability = nil }
            
            let icon = hourlyData["icon"] as? String
            guard let validIcon = icon else { return }
            
            let temp = hourlyData["temperature"] as? Double
            guard let validTemp = temp else { return }
            
            let hourlyWeather = HourlyWeather(timeInterval: timeInterval, precipProbability: precipProbability, weatherIcon: validIcon, temp: validTemp)
            hourlyWeathers.append(hourlyWeather)
        }
        
        
        // daily process
        let daily = json["daily"] as? [String: Any]
        
        guard let validDaily = daily else { return }
        let dailyDatas = validDaily["data"] as? [[String: Any]]
        
        guard let validDailyDatas = dailyDatas else { return }
        let validDailyData = validDailyDatas[0]
        
        let tempMax = validDailyData["temperatureMax"] as? Double
        guard let validTempMax = tempMax else { return }
        
        // tempMin
        let tempMin = validDailyData["temperatureMin"] as? Double
        guard let validTempMin = tempMin else { return }

        
        let sunriseTime = validDailyData["sunriseTime"] as? Int
        guard let validSunriseTime = sunriseTime else { return }
        let sunrise = TimeInterval(exactly: validSunriseTime)!

        let sunsetTime = validDailyData["sunsetTime"] as? Int
        guard let validSunsetTime = sunsetTime else { return }
        let sunset = TimeInterval(exactly: validSunsetTime)!

        var dailyWeathers: [DailyWeather] = []
        for dailyData in validDailyDatas {
            
            //timeInterval
            let time = dailyData["time"] as? Int
            guard let validTime = time else { return }
            let timeInterval = TimeInterval(exactly: validTime)!
            
            //icon
            let icon = dailyData["icon"] as? String
            guard let validIcon = icon else { return }
            
            // tempMax
            let tempMax = dailyData["temperatureMax"] as? Double
            guard let validTempMax = tempMax else { return }

            // tempMin
            let tempMin = dailyData["temperatureMin"] as? Double
            guard let validTempMin = tempMin else { return }
            
            let dailyWeather = DailyWeather(timeInterval: timeInterval, weatherIcon: validIcon, tempMax: validTempMax, tempMin: validTempMin)
            dailyWeathers.append(dailyWeather)
        }
        
        let detailCity = DetailCity(cityID: cityID, name: name, timezone: timezone, summary: validSummary, hourlyWeathers: hourlyWeathers, dailyWeathers: dailyWeathers, temp: validTemp, tempMax: validTempMax, tempMin: validTempMin, sunrise: sunrise, sunset: sunset, precipProbability: validPrecipProbability, humidity: validHumidity, windSpeed: validWindSpeed, windBearing: validWindBearing, apparentTemp: validApparentTemp, precipIntensity: validPrecipIntensity, pressure: validPressure, visibility: validVisibility, uvIndex: validUvIndex, weatherIcon: validWeatherIcon)
        
        self.delegate?.parsingDidFinished(result: detailCity, parsingType: .detail)
    }
}
