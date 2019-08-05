//
//  TitleView.swift
//  Weather
//
//  Created by user on 04/08/2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit

class TitleView: UIStackView {
    var titleLabel: UILabel = UILabel()
    var subtitleLabel: UILabel = UILabel()
    
    func set(_ title: String, subtitle: String) {
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.headline)
        titleLabel.textColor = .black
        
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.footnote)
        subtitleLabel.textColor = titleLabel.textColor.withAlphaComponent(0.75)
        
        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(subtitleLabel)
        self.distribution = .equalCentering
        self.alignment = .center
        self.axis = .vertical
    }
    
    func update(subtitle: String) {
        subtitleLabel.text = subtitle
    }
}
