//
//  BuilderProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol BuilderProtocol {
    func createProfileModule(currentPeopleDelegate: CurrentPeopleDataDelegate?,
                             router: RouterProfileProtocol) -> UIViewController
    
    func createAdminPanelModule(router: RouterProfileProtocol) -> UIViewController
}
