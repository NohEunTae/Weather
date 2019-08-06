//
//  SearchResultViewController.swift
//  Weather
//
//  Created by user on 05/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import MapKit

protocol SearchResultViewControllerDelegate: AnyObject {
    func searchDidFinished(item: MKMapItem)
    func tableViewBeginDragging()
}

extension SearchResultViewControllerDelegate {
    func tableViewBeginDragging() {}
}

class SearchResultViewController: UIViewController {

    @IBOutlet weak var searchIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultTableView: UITableView!
    private let completer = MKLocalSearchCompleter()
    private var matchingItems: [MKMapItem] = []
    private var memorizingItems: [String : [MKMapItem]] = [:]
    private weak var timer: Timer? = nil
    
    weak var delegate: SearchResultViewControllerDelegate? = nil

    init() {
        super.init(nibName: "SearchResultViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        completer.delegate = self
        setupResultTableView()
    }
    
    func setupResultTableView() {
        resultTableView.keyboardDismissMode = .interactive
        resultTableView.delegate = self
        resultTableView.dataSource = self
        let nibCell = UINib(nibName: "SearchCityTableViewCell", bundle: nil)
        resultTableView.register(nibCell, forCellReuseIdentifier: "SearchCityTableViewCell")
    }
}

extension SearchResultViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegate?.tableViewBeginDragging()
    }
}

extension SearchResultViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.searchDidFinished(item: self.matchingItems[indexPath.row])
        }
    }
}

extension SearchResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCityTableViewCell") as! SearchCityTableViewCell
        cell.cityName.text = matchingItems[indexPath.row].placemark.title!
        return cell

    }
}

extension SearchResultViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        
        if completer.isSearching {
            completer.cancel()
        }
        
        if let isMemorized = memorizingItems[searchBarText] {
            matchingItems = isMemorized
            DispatchQueue.main.async { [weak self] in
                self?.resultTableView.isHidden = false
                self?.searchIndicator.stopAnimating()
                self?.resultTableView.reloadData()
            }
        } else {
            let maybeInclude = memorizingItems.keys.filter { searchBarText.contains($0)}.last
            if let include = maybeInclude {
                let maybeItems = memorizingItems[include]?.filter { $0.placemark.title != nil}.filter { $0.placemark.title!.contains(searchBarText)}
                if let items = maybeItems {
                    memorizingItems.updateValue(items, forKey: searchBarText)
                    matchingItems = items
                }
            }
            timer?.invalidate()
            timer = nil
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerFunc), userInfo: searchBarText, repeats: false)
            DispatchQueue.main.async { [weak self] in
                self?.resultTableView.isHidden = true
                self?.searchIndicator.startAnimating()
            }
        }
    }
    
    @objc func timerFunc(_ timer: Timer) {
        completer.queryFragment = timer.userInfo as! String
    }
}

extension SearchResultViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.matchingItems.removeAll()

        let overlapData = completer.results.filter { $0.subtitle == "" }
        var maybeCities: [String] = []

        for item in overlapData {
            let split = item.title.split(separator: ",").map { String($0) }
            for string in split {
                if string.contains(completer.queryFragment), !maybeCities.contains(string) {
                    maybeCities.append(string)
                    break
                }
            }
        }

        if let memorizedItems = memorizingItems[completer.queryFragment] {
            matchingItems.append(contentsOf: memorizedItems)
            for item in memorizedItems {
                let maybeInclude = maybeCities.filter { $0.contains(item.placemark.title!)}
                for item in maybeInclude {
                    maybeCities.remove(at: maybeCities.firstIndex(of: item)!)
                }
            }
        }
        
        let group = DispatchGroup()
        let request = MKLocalSearch.Request()
        for maybeCity in maybeCities {
            group.enter()
            request.naturalLanguageQuery = maybeCity
            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                guard let self = self else { return }
                guard let response = response else {
                    group.leave()
                    return
                }
                for item in response.mapItems {
                    let titles = self.matchingItems.map { $0.placemark.title }
                    if let title = item.placemark.title, !titles.contains(title), title.contains(completer.queryFragment) {
                        self.matchingItems.append(item)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.memorizingItems.updateValue(self.matchingItems, forKey: completer.queryFragment)
            self.searchIndicator.stopAnimating()
            self.resultTableView.isHidden = false
            self.resultTableView.reloadData()
        }
    }
}
