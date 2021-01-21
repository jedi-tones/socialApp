//
//  ModuleBuilder.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

class ModuleBuilder: BuilderProtocol {
    
    func createProfileModule(currentPeopleDelegate: CurrentPeopleDataDelegate?,
                             router: RouterProfileProtocol) -> UIViewController {
        
        let viewController = ProfileViewController()
        let presenter = ProfilePresenter(view: viewController,
                                         currentPeopleDelegate: currentPeopleDelegate,
                                         router: router)
        viewController.presenter = presenter
        return viewController
    }
    
    
    func createAdminPanelModule(router: RouterProfileProtocol) -> UIViewController {
        let viewController = AdminPanelViewController()
        let presenter = AdminPanelPresentor(view: viewController, router: router)
        viewController.presenter = presenter
        
        return viewController
    }

}
