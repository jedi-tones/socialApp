//
//  MAdminPanelSettings.swift
//  socialApp
//
//  Created by Денис Щиголев on 23.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

enum MAdminPanelSettings: Int, CaseIterable, CollectionCellModel {
    
    case info
    case settings
    case backupAllUsers
    case updateGeoHash
    
    func description() -> String {
        switch self {
        
        case .info:
            return "Информация"
        case .settings:
            return "Настройки"
        case .backupAllUsers:
            return "backup all users"
        case .updateGeoHash:
            return "update geohashAllUser"
        }
    }
}
