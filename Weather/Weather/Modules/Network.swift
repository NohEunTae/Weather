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
        case success(_ data: Data)
        case failed(_ error: Error)
    }

    static func request(urlPath: String, completion:@escaping (_ result: NetworkResult)->()) {
        let url = URL(string: urlPath)
        let urlSession = URLSession.shared

        let task = urlSession.dataTask(with: url! as URL) { (data, response, error) -> Void in
            error == nil ? completion(.success(data!)) : completion(.failed(error!))
        }
        task.resume()
    }
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
