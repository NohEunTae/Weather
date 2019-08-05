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
}

class SearchResultViewController: UIViewController {

    @IBOutlet weak var searchIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultTableView: UITableView!
    private var search: MKLocalSearch? = nil
    private let completer = MKLocalSearchCompleter()
    var matchingItems: [MKMapItem] = []

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
        
        self.resultTableView.delegate = self
        self.resultTableView.dataSource = self
        let nibCell = UINib(nibName: "SearchCityTableViewCell", bundle: nil)
        resultTableView.register(nibCell, forCellReuseIdentifier: "SearchCityTableViewCell")

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
        DispatchQueue.main.async {
            self.resultTableView.isHidden = true
            self.searchIndicator.startAnimating()
        }
        
        if completer.isSearching {
            self.matchingItems.removeAll()
            self.completer.cancel()
            DispatchQueue.main.async {
                self.resultTableView.reloadData()
            }
        }
        completer.queryFragment = searchBarText
    }
}

extension SearchResultViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        let overlapData = completer.results.filter { $0.subtitle == "" }
        var maybeCities: [String] = []
        
        for item in overlapData {
            let split = item.title.split(separator: ",").map { String($0) }
            
            for string in split {
                if string.contains(completer.queryFragment), !maybeCities.contains(string) {
                    maybeCities.append(string)
                    print(string)
                    break
                }
            }
        }
        
        let group = DispatchGroup()
        for maybeCity in maybeCities {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = maybeCity
            let search = MKLocalSearch(request: request)
            search.start { [unowned self] response, _ in
                guard let response = response else {
                    group.leave()
                    return
                }
                
                for item in response.mapItems {
                    let names = self.matchingItems.map { $0.name }
                    if !names.contains(item.name) {
                        self.matchingItems.append(item)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.searchIndicator.stopAnimating()
            self.resultTableView.isHidden = false
            self.resultTableView.reloadData()
        }
    }
}
