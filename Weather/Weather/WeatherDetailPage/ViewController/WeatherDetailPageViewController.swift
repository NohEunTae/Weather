//
//  WeatherDetailPageViewController.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class WeatherDetailPageViewController: UIViewController {
    
    var pageViewController: UIPageViewController!
    let cities: [ConciseCity]
    let startIndex: Int
    
    init (startIndex: Int, cities: [ConciseCity]) {
        self.startIndex = startIndex
        self.cities = cities
        super.init(nibName: "WeatherDetailPageViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        self.pageViewController.dataSource = self
        
        guard let maybefirstViewController = self.viewController(at: startIndex) else {
            return
        }
        
        let startingViewController: WeatherDetailViewController = maybefirstViewController
        let viewControllers = [startingViewController]
        self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
        
        self.addChild(pageViewController)
        self.view.addSubview(pageViewController.view)
        
        let pageViewRect = self.view.bounds
        pageViewController.view.frame = pageViewRect
        pageViewController.didMove(toParent: self)
    }

    // 특정 index에 해당하는 viewcontroller를 구한다
    func viewController(at index: Int) -> WeatherDetailViewController? {
        if (self.cities.isEmpty || self.cities.count <= index) {
            return nil
        }
        
        let dataViewController = WeatherDetailViewController(city: self.cities[index], index: index)
        dataViewController.delegate = self
        return dataViewController
    }
}

extension WeatherDetailPageViewController: UIPageViewControllerDataSource {
    
    // 이전 페이지에 대한 정보를 구한다.
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as? WeatherDetailViewController
        
        guard let index = vc?.pageIndex else {
            return nil
        }
        
        return index == 0 ? nil : self.viewController(at: index - 1)
    }
    
    // 다음 페이지에 대한 정보를 구한다
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as? WeatherDetailViewController
        
        guard let index = vc?.pageIndex else {
            return nil
        }
        return index == self.cities.count ? nil : self.viewController(at: index + 1)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.cities.count
    }
}

extension WeatherDetailPageViewController: WeatherDetailViewControllerDelegate {
    func scrollDown() {
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func scrollUp() {
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    func viewDidLoadCalled(_ index: Int) {
        DispatchQueue.main.async {
            self.title = self.cities[index].name
        }
    }
}
