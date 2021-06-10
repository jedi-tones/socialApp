//
//  AboutView.swift
//  socialApp
//
//  Created by Денис Щиголев on 23.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class ContactsView: UIView {
    
    private let emailHeader = UILabel(labelText: MLabels.contactsEmailHeader.rawValue,
                              textFont: .avenirRegular(size: 16),
                              linesCount: 0)
    private  let emailButton = OneLineButton(info: MLinks.email.rawValue, font: .avenirBold(size: 16))
    
    private var versionHeader = UILabel(labelText: MLabels.contactsVersionHeader.rawValue,
                                      textFont: .avenirRegular(size: 16),
                                      linesCount: 0)
    
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
        versionLabel.text = "Версия: \(version)"
    }
    
    private func getAppCurrentVersionNumber() -> String? {
        let nsObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject?
        return nsObject as? String
    }
    
    func configure(delegate: Any?, emailSelector: Selector){
        emailButton.addTarget(delegate, action: emailSelector, for: .touchUpInside)
    }
    
    
}


extension ContactsView {
    private func setupConstraints() {
        emailHeader.translatesAutoresizingMaskIntoConstraints = false
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        versionHeader.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(emailHeader)
        addSubview(emailButton)
        addSubview(versionHeader)
        addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            emailHeader.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            emailHeader.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailHeader.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            emailButton.topAnchor.constraint(equalTo: emailHeader.bottomAnchor, constant: 20),
            emailButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            versionHeader.topAnchor.constraint(equalTo: emailButton.bottomAnchor, constant: 20),
            versionHeader.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            versionHeader.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            versionLabel.topAnchor.constraint(equalTo: versionHeader.bottomAnchor, constant: 20),
            versionLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
}
