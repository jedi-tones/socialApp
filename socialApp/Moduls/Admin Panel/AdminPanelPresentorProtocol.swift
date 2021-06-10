//
//  AdminPanelPresentorProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

protocol AdminPanelPresentorProtocol: class {
    init(view: AdminPanelViewProtocol, router: RouterProfileProtocol)
    func updateGeoHash()
    func backupUsers()
}
