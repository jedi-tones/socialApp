//
//  MDeeplinkTypes.swift
//  socialApp
//
//  Created by Денис Щиголев on 21.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

enum MDeeplinkTypes {
    case chat(friendID: String)
    case chats
    case main
    case requests
    
    var description: String {
        switch self {
        
        case .chat(friendID: _):
            return "chatFriendID"
        case .chats:
            return "chats"
        case .main:
            return "main"
        case .requests:
            return "requests"
        }
    }
}
