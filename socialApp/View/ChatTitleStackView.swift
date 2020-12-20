//
//  ChatTitleView.swift
//  socialApp
//
//  Created by Денис Щиголев on 25.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SDWebImage

class ChatTitleStackView: UIStackView {
    
    private var chat: MChat?
    private let peopleImageButton = UIButton()
    private let peopleNameLabel = UILabel(labelText: "Test", textFont: .avenirBold(size: 16), textColor: .myLabelColor())
    private let peopleOnlineLabel = UILabel(labelText: "", textFont: .avenirBold(size: 16), textColor: .mySecondSatColor())
    
    convenience init(chat: MChat, target: Any, profileTappedAction: Selector) {
        self.init()
        self.chat = chat
        
        setup()
        setupConstraints()
        peopleImageButton.addTarget(target, action: profileTappedAction, for: .touchUpInside)
    }
    
    func changePeopleStatus(isOnline: Bool) {
        peopleOnlineLabel.text = isOnline ? "в чате" : ""
    }
    
    private func setup() {
        guard let chat = chat else { return }
        guard let imageURL = URL(string: chat.friendUserImageString) else { return }
        peopleImageButton.sd_setImage(with: imageURL, for: .normal, completed: nil)
        peopleImageButton.imageView?.contentMode = .scaleAspectFill
        peopleImageButton.isUserInteractionEnabled = true
        peopleImageButton.clipsToBounds = true
        
        peopleNameLabel.text = chat.friendUserName
        
        changePeopleStatus(isOnline: chat.friendInChat)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        peopleImageButton.layer.cornerRadius = peopleImageButton.frame.height / 4
        peopleImageButton.layer.frame.size.width = peopleImageButton.frame.height
    }
}

extension ChatTitleStackView {
    private func setupConstraints() {
        
        addArrangedSubview(peopleImageButton)
        addArrangedSubview(peopleNameLabel)
        addArrangedSubview(peopleOnlineLabel)
        
        alignment = .center
        spacing = 15
        axis = .horizontal
        
        peopleImageButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            peopleImageButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7),
            peopleImageButton.widthAnchor.constraint(equalTo: peopleImageButton.heightAnchor)
        ])
    }
}
