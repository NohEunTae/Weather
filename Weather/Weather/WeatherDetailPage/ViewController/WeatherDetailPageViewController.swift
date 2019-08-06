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
    var cities: [ConciseCity]
    let startIndex: Int
    
    var currentIndex: Int
    
    init (startIndex: Int, cities: [ConciseCity]) {
        self.startIndex = startIndex
        self.cities = cities
        currentIndex = startIndex
        super.init(nibName: "WeatherDetailPageViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        navigationItem.setHidesBackButton(true, animated: false)
        
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [WeatherDetailPageViewController.self])
        pageControl.currentPageIndicatorTintColor = UIColor.gray
        pageControl.pageIndicatorTintColor = UIColor(red: (240/255), green: (240/255), blue: (240/255), alpha: 1)
        pageControl.backgroundColor = UIColor.white
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        setupPageViewController(index: startIndex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupPageViewController(index: Int) {
        DispatchQueue.main.async {
            guard let maybefirstViewController = self.viewController(at: index) else {
                return
            }
            let startingViewController: WeatherDetailViewController = maybefirstViewController
            let startingNavigationController = UINavigationController(rootViewController: startingViewController)
            let viewControllers = [startingNavigationController]
            
            self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
            self.addChild(self.pageViewController)
            self.view.addSubview(self.pageViewController.view)
            
            let pageViewRect = self.view.bounds
            self.pageViewController.view.frame = pageViewRect
            self.pageViewController.didMove(toParent: self)
            self.pageViewController.setNeedsStatusBarAppearanceUpdate()
        }
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

extension WeatherDetailPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let currentViewController = pageViewController.viewControllers?.first as? UINavigationController,
                let detailViewController = currentViewController.viewControllers.first as? WeatherDetailViewController {
                currentIndex = detailViewController.pageIndex
            }
        }
    }
}

extension WeatherDetailPageViewController: UIPageViewControllerDataSource {
    // 이전 페이지에 대한 정보를 구한다.
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let nv = viewController as? UINavigationController
        let vc = nv?.viewControllers.first as? WeatherDetailViewController
        
        guard let index = vc?.pageIndex else {
            return nil
        }
        return index == 0 ? nil : UINavigationController(rootViewController: self.viewController(at: index - 1)!)
    }
    
    // 다음 페이지에 대한 정보를 구한다
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nv = viewController as? UINavigationController
        let vc = nv?.viewControllers.first as? WeatherDetailViewController

        guard let index = vc?.pageIndex else {
            return nil
        }
        return index == self.cities.count - 1 ? nil : UINavigationController(rootViewController: self.viewController(at: index + 1)!)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.cities.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.currentIndex
    }
}

extension WeatherDetailPageViewController: WeatherDetailViewControllerDelegate {
    func listButtonClicked() {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension WeatherDetailPageViewController: WeatherListViewControllerDelegate {
    func addUserWeather(user: ConciseCity) {
        cities.insert(user, at: 0)
        currentIndex += 1
        setupPageViewController(index: currentIndex)
    }
    
    func deleteUserWeather() {
        cities.removeFirst()
        currentIndex = currentIndex == 0 ? 0 : currentIndex - 1
        setupPageViewController(index: currentIndex)
    }
}
