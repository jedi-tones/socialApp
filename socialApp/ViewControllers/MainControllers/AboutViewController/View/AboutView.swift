//
//  AboutView.swift
//  socialApp
//
//  Created by Денис Щиголев on 09.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class AboutView: UIView {
    
    private let siteButton = OneLineButton(info: "Наш сайт",
                                           font: .avenirBold(size: 16))
    private let termsOfServiceButton = OneLineButton(info: "Условия и положения",
                                                     font: .avenirBold(size: 16))
    private let privacyButton = OneLineButton(info: "Политика конфиденциальности",
                                              font: .avenirBold(size: 16))
    private var versionLabel = UILabel(labelText: "",
                                      textFont: .avenirBold(size: 16),
                                      linesCount: 0)
    init(){
        super.init(frame: .zero)
        setup()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(){
        backgroundColor = .myWhiteColor()
        let version = getAppCurrentVersionNumber() ?? "1.0.22*"
        versionLabel.text = "Версия программы: \(version)"
    }
    
    private func getAppCurrentVersionNumber() -> String? {
        let nsObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject?
        return nsObject as? String
    }
    
    func configure(delegate: Any?,siteButtonSelector: Selector, termsOfServiceSelector: Selector, privacyButtonSelector: Selector){
        siteButton.addTarget(delegate, action: siteButtonSelector, for: .touchUpInside)
        termsOfServiceButton.addTarget(delegate, action: termsOfServiceSelector, for: .touchUpInside)
        privacyButton.addTarget(delegate, action: privacyButtonSelector, for: .touchUpInside)
    }
}


extension AboutView {
    private func setupConstraints() {
        termsOfServiceButton.translatesAutoresizingMaskIntoConstraints = false
        privacyButton.translatesAutoresizingMaskIntoConstraints = false
        siteButton.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(siteButton)
        addSubview(termsOfServiceButton)
        addSubview(privacyButton)
        addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            siteButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            siteButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            termsOfServiceButton.topAnchor.constraint(equalTo: siteButton.bottomAnchor, constant: 20),
            termsOfServiceButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            privacyButton.topAnchor.constraint(equalTo: termsOfServiceButton.bottomAnchor, constant: 20),
            privacyButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            versionLabel.topAnchor.constraint(equalTo: privacyButton.bottomAnchor, constant: 20),
            versionLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
}
