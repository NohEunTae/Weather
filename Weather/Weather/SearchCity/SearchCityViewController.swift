//
//  SearchCityViewController.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import MapKit

class SearchCityViewController: UIViewController {
    var isCancelButtonClicked = false
    weak var delegate: SearchResultTableViewControllerDelegate? = nil
    
    init() {
        super.init(nibName: "SearchCityViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        self.title = "도시 이름 입력"
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        let tableViewController = SearchResultTableViewController()
        tableViewController.delegate = self
        let searchController = UISearchController(searchResultsController: tableViewController)
        navigationItem.searchController = searchController
        navigationItem.searchController?.searchResultsUpdater = tableViewController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        navigationItem.searchController?.delegate = self
        navigationItem.searchController?.searchBar.delegate = self
    }
}

extension SearchCityViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        if isCancelButtonClicked {
            DispatchQueue.main.async { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension SearchCityViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isCancelButtonClicked = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if isCancelButtonClicked {
            DispatchQueue.main.async { [unowned self] in
                self.navigationItem.searchController?.dismiss(animated: true)
            }
        }
    }
}

extension SearchCityViewController: SearchResultTableViewControllerDelegate {
    func searchDidFinished(item: MKMapItem) {
        DispatchQueue.main.async { [unowned self] in
            self.navigationController?.popViewController(animated: true)
            self.delegate?.searchDidFinished(item: item)
        }
    }
}
