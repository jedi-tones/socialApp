//
//  OneLikebutton.swift
//  socialApp
//
//  Created by Денис Щиголев on 18.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class OneLikeButton: UIButton {
    
    let infoLabel  = UILabel(labelText: "", textFont: .avenirRegular(size: 14),textColor: .myGrayColor())
    let bottomLine = UIView(frame: .zero)
    
    convenience init(info: String) {
        self.init()
        infoLabel.text = info
        bottomLine.backgroundColor = .myLightGrayColor()
        setupConstraints()
    }
    
    private func setupConstraints() {
        addSubview(infoLabel)
        addSubview(bottomLine)
        
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: topAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            bottomLine.bottomAnchor.constraint(equalTo: infoLabel.bottomAnchor,constant: 3),
            bottomLine.leadingAnchor.constraint(equalTo: infoLabel.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: infoLabel.trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
}
