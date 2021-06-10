//
//  MMessageRealm.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import RealmSwift

class MMessageRealm: Object {
    @objc dynamic var messageID = ""
    @objc dynamic var sendDate = Date()
    
    @objc dynamic var senderId = ""
    @objc dynamic var displayName = ""
    @objc dynamic var content: String? = nil
    @objc dynamic var imageURL: String? = nil
    
    let sender = LinkingObjects(fromType: MChatRealm.self, property: "messages")
    override static func primaryKey() -> String? {
        "messageID"
    }
}
