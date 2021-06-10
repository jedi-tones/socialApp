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
    
    func addChatToRealm(chats: [MChatRealm], complition: @escaping (Result<[MChatRealm], Error>) -> Void) {
        realmService.appendToRealm(objects: chats, complition: complition)
    }
    
    func logoutClearRealmData(complition: @escaping (Result<(),Error>)-> Void) {
        realmService.deleteAllRealm(complition: complition)
    }
    
    
}

