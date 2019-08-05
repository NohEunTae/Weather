//
//  Clock.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation

protocol ClockDelegate: AnyObject {
    func minuteChanged()
}

class Clock {
    weak private var timer: Timer? = nil
    weak var delegate: ClockDelegate? = nil
    
    func stopClock() {
        timer?.invalidate()
        timer = nil
    }
    
    func startClock() {
        stopClock()

        let date = Date()
        let calendar = NSCalendar.current
        let second = calendar.component(.second, from: date)

        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(60 - second), repeats: false) { [weak self] timer in
            self?.delegate?.minuteChanged()
            self?.stopClock()
            self?.startClockFromZeroSecond()
        }
    }
    
    private func startClockFromZeroSecond() {
        stopClock()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] timer in
            self?.delegate?.minuteChanged()
        }
    }
}
