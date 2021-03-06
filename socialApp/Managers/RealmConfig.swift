//
//  RealmConfig.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import RealmSwift

final class RealmConfig {
    static let shared = RealmConfig()
    private init() { }
    
    func setDefaultRealm() {
        var config = Realm.Configuration(schemaVersion: 1,
                                         migrationBlock: { migration, oldSchemaVersion in
                                            if oldSchemaVersion < 1 {
                                                
                                            }
        })
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("flava.realm")
        print(config.fileURL?.absoluteURL ?? "" )
        Realm.Configuration.defaultConfiguration = config
    }
}
