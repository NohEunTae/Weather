//
//  UIViewController+Extension.swift
//  Weather
//
//  Created by user on 07/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlert(_ title: String, message: String, completion: (()-> ())?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let confirm = UIAlertAction(title: "확인", style: .cancel)
        alert.addAction(confirm)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true, completion: {
                completion?()
            })
        }
    }
}
