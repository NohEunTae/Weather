//
//  UITableViewCell+Extension.swift
//  Weather
//
//  Created by user on 02/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

protocol ImageDownload {
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ())
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> ())
}

extension ImageDownload {
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> ()) {
        self.getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            completion(UIImage(data: data))
        }
    }
}

extension UITableViewCell: ImageDownload {}
extension UICollectionViewCell: ImageDownload {}
