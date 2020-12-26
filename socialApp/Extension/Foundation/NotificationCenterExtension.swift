//
//  NotificationCenterExtension.swift
//  socialApp
//
//  Created by Денис Щиголев on 18.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

extension NotificationCenter {
    static func postCurrentUserNeedUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("currentUser"), object: nil)
    }
    
    static func postPremiumUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("premiumUpdate"), object: nil)
    }
    
    static func postSearchSettingsNeedUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("searchSettingsUpdate"), object: nil)
    }
    
    static func postFCMKeyNeedUpdate(data: [AnyHashable : Any]?) {
        NotificationCenter.default.post(name: NSNotification.Name("firebaseMessageToken"), object: nil, userInfo: data)
    }
    
    static func postFCMKeyInChatsNeedUpdate(data: [AnyHashable : Any]?) {
        NotificationCenter.default.post(name: NSNotification.Name("firebaseMessageTokenInChats"), object: nil, userInfo: data)
    }
    
    static func postUserAvatarInChatsNeedUpdate(newImageStringURL: String) {
        let data = [MChat.CodingKeys.friendUserImageString.rawValue : newImageStringURL]
        NotificationCenter.default.post(name: NSNotification.Name("userAvatarWasUpdated"), object: nil, userInfo: data)
    }
    
    static func postRequestCountIsChange(requestCount: Int) {
        let data = ["requestCount" : requestCount]
        NotificationCenter.default.post(name: NSNotification.Name("requestCountIsChange"), object: nil, userInfo: data)
    }
    
    static func postCoordinatesIsUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("coordinatesIsUpdate"), object: nil)
    }
    
    static func addObsorverToCurrentUser(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("currentUser"),
                                               object: nil)
    }
    
    static func addObsorverToPremiumUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("premiumUpdate"),
                                               object: nil)
    }
    
    static func addObsorverToSearchSettingsNeedUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("searchSettingsUpdate"),
                                               object: nil)
    }
    
    static func addObsorverToFCMKeyUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("firebaseMessageToken"),
                                               object: nil)
    }
    
    static func addObsorverToFCMKeyInChatsUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("firebaseMessageTokenInChats"),
                                               object: nil)
    }
    
    static func addObsorverToUserAvatarInChatsNeedUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("userAvatarWasUpdated"),
                                               object: nil)
    }
    
    static func addObsorverRequestCountIsChange(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("requestCountIsChange"),
                                               object: nil)
    }
    
    static func addObsorverCoordinatesIsUpdate(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: NSNotification.Name("coordinatesIsUpdate"),
                                               object: nil)
    }
    
}
