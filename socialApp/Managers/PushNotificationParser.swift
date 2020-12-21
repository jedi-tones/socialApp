//
//  PushNotificationParser.swift
//  socialApp
//
//  Created by Денис Щиголев on 21.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class PushNotificationParser {
    
    static let shared = PushNotificationParser()
    private init() { }
    
    func handleNotificationDeeplink(_ userInfo: [AnyHashable : Any]) -> MDeeplinkTypes? {
        if let chatFriendID = userInfo[MDeeplinkTypes.chat(friendID: "").description] as? String {
            return MDeeplinkTypes.chat(friendID: chatFriendID)
        } else if let _ = userInfo[MDeeplinkTypes.chats.description] as? String {
            return MDeeplinkTypes.chats
        } else if let _ = userInfo[MDeeplinkTypes.main.description] as? String {
            return MDeeplinkTypes.main
        } else if let _ = userInfo[MDeeplinkTypes.requests.description] as? String {
            return MDeeplinkTypes.requests
        }
        return nil
    }
}

