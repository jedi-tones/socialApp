//
//  DeeplinkNavigator.swift
//  socialApp
//
//  Created by Денис Щиголев on 21.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class DeeplinkNavigator {
    static let shared = DeeplinkNavigator()
    private init() {}
    
    private weak var mainTabBarDelegate: MainTabBarDelegate?
    
    func proceedToDeeplink(_ type: MDeeplinkTypes) {
        guard let mainTabBarDelegate = mainTabBarDelegate else { return }
        DeeplinkManager.shared.resetDeeplink()
        
        switch type {
        
        case .chat(friendID: let id):
            mainTabBarDelegate.showChatWith(friendID: id)
        case .chats:
            print( "chats")
        case .main:
            print( "main")
        case .requests:
            print( "requests")
        }
    }
    
    func setupDelegate(mainTabBarDelegate: MainTabBarDelegate?) {
        self.mainTabBarDelegate = mainTabBarDelegate
    }
}
