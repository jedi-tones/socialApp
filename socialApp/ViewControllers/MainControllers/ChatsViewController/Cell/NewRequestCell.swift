//
//  NewRequestCell.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class NewRequestCell: UICollectionViewCell {
    static var reuseID: String = "NewRequestCell"
    
    let conteinerView = UIView()
    let heartImageView = UIImageView(systemName: "heart.fill",
                                     contentMode: .scaleAspectFit,
                                     config: UIImage.SymbolConfiguration(weight: .bold),
                                     tint: .white)
    let countLabel = UILabel(labelText: "",
                             textFont: .avenirBold(size: 12),
                             textColor: .mySecondSatColor(),
                             aligment: .center)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupConstraints()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(requestCount: Int) {
       
        if requestCount > 0 {
            countLabel.text = "\(requestCount)"
        } else {
            countLabel.text = ""
        }
    }
    
    private func setup() {
        backgroundColor = .myWhiteColor()
        conteinerView.backgroundColor = .mySecondSatColor()
        conteinerView.layer.cornerRadius = MDefaultLayer.smallCornerRadius.rawValue
        conteinerView.clipsToBounds = true
    }
    
    private func setupConstraints(){
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        conteinerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(conteinerView)
        addSubview(heartImageView)
        addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            conteinerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            conteinerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            conteinerView.topAnchor.constraint(equalTo: topAnchor),
            conteinerView.heightAnchor.constraint(equalTo: conteinerView.widthAnchor),
            
            heartImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            heartImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            heartImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            heartImageView.heightAnchor.constraint(equalTo: heartImageView.widthAnchor),
            
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            countLabel.topAnchor.constraint(equalTo: conteinerView.bottomAnchor, constant: 10),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
