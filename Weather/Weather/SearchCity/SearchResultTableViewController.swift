//
//  SearchResultTableViewController.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import MapKit
import UIKit

protocol SearchResultTableViewControllerDelegate: AnyObject {
    func searchDidFinished(item: MKMapItem)
}


class SearchResultTableViewController: UITableViewController {
    var matchingItems: [MKMapItem] = []
    weak var delegate: SearchResultTableViewControllerDelegate? = nil
    
    init() {
        super.init(nibName: "SearchResultTableViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nibCell = UINib(nibName: "SearchCityTableViewCell", bundle: nil)
        tableView.register(nibCell, forCellReuseIdentifier: "SearchCityTableViewCell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCityTableViewCell") as! SearchCityTableViewCell
        cell.cityName.text = matchingItems[indexPath.row].placemark.administrativeArea!
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { [unowned self] in
            self.delegate?.searchDidFinished(item: self.matchingItems[indexPath.row])
        }
    }
}

extension SearchResultTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        let mapView = MKMapView()
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            guard let response = response else {
                return
            }
            self?.matchingItems = response.mapItems.filter { $0.placemark.administrativeArea != nil }
            DispatchQueue.main.async { [weak self] in 
                self?.tableView.reloadData()
                mapView.removeAnnotations(mapView.annotations)
            }
        }
    }
}
