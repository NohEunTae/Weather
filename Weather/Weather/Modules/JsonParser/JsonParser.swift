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
    
    func startParsing(data: Data, parsingType: ParsingType, cityName: String? = nil, savedCities: [DefaultCity]? = nil) {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        switch parsingType {
        case .city:
            guard let validCityName = cityName else { return }
            parsingCity(json: json, cityName: validCityName)
        case .cities:
            guard let validCities = savedCities else { return }
            parsingCities(json: json, defaultCities: validCities)
        case .detail:
            break
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
}
