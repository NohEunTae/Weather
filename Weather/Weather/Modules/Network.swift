//
//  Network.swift
//  Weather
//
//  Created by user on 01/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation


struct Network {
    enum NetworkResult {
        case success
        case failed
    }

    static func request(urlPath: String, completion:@escaping (_ result: NetworkResult, _ data: Data?)->()) {
        let url = URL(string: urlPath)
        let urlSession = URLSession.shared

        let task = urlSession.dataTask(with: url! as URL) { (data, response, error) -> Void in
            if error == nil {
                completion(.success, data)
            } else {
                completion(.failed, nil)
            }
        }
        task.resume()
    }
}
