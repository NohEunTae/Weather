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
    var matchingItems: [MKMapItem] = []
    weak var timer: Timer? = nil
    
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
        self.resultTableView.keyboardDismissMode = .interactive
        self.resultTableView.delegate = self
        self.resultTableView.dataSource = self
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
        dismiss(animated: true) { [unowned self] in
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
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFunc), userInfo: searchBarText, repeats: false)
        if completer.isSearching {
            self.completer.cancel()
        }

        DispatchQueue.main.async {
            self.resultTableView.isHidden = true
            self.searchIndicator.startAnimating()
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
        
        print(maybeCities.count)

        let group = DispatchGroup()
        let request = MKLocalSearch.Request()
        for maybeCity in maybeCities {
            group.enter()
            
            request.naturalLanguageQuery = maybeCity

            let search = MKLocalSearch(request: request)
            search.start { [unowned self] response, error in
                guard let response = response else {
                    print(error?.localizedDescription)
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
        
        group.notify(queue: .main) {
            print(self.matchingItems.count)
            self.searchIndicator.stopAnimating()
            self.resultTableView.isHidden = false
            self.resultTableView.reloadData()
        }
    }
}
