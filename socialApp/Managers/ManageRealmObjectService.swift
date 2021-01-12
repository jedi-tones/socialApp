//
//  CreateRealmObjectService.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class ManageRealmObjectService {
    static let shared = ManageRealmObjectService()
    
    private let realmService = RealmService()
    private let modelConverterService = ModelConverterService()
    
    private init() { }
    
    func addChatToRealm(chat: MChat, complition: @escaping (Result<MChatRealm, Error>) -> Void) {
        let realmChat = modelConverterService.createRealmChat(chat: chat)
        realmService.appendToRealm(object: realmChat, complition: complition)
    }
    
    func addMessageToRealm(message: MMessage,  complition: @escaping (Result<MMessageRealm, Error>) -> Void) {
        let realmMessage = modelConverterService.createRealmMessage(message: message)
        realmService.appendToRealm(object: realmMessage, complition: complition)
    }
    
    
}

