//
//  DeeplinkManager.swift
//  socialApp
//
//  Created by Денис Щиголев on 21.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class DeeplinkManager {
    static let shared = DeeplinkManager()
    
    private init() { }
    private var deeplinkType: MDeeplinkTypes?
    
    func checkDeeplink() {
        guard let deeplinkType = deeplinkType else {
            return
        }
        
        DeeplinkNavigator.shared.proceedToDeeplink(deeplinkType)
    }
    
    func resetDeeplink() {
        // reset deeplink after handling
        deeplinkType = nil
    }
    
    func handleRemoteNotification(_ notificationUserInfo: [AnyHashable: Any]) {
        
        deeplinkType = PushNotificationParser.shared.handleNotificationDeeplink(notificationUserInfo)
    }
}
