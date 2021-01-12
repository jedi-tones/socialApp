//
//  ModelConverterService.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import RealmSwift

class ModelConverterService {
    
     func createRealmChat(chat: MChat) -> MChatRealm {
        
        let realmChat = MChatRealm()
        
        return realmChat
    }
    
     func createRealmMessage(message: MMessage) -> MMessageRealm {
        
        let realmMessage = MMessageRealm()
        
        realmMessage.messageID = message.messageId
        realmMessage.sendDate = message.sentDate
        realmMessage.senderId = message.sender.senderId
        realmMessage.displayName = message.sender.displayName
        realmMessage.content = message.content
        realmMessage.imageURL = message.imageURL?.absoluteString
        
        return realmMessage
    }
}
