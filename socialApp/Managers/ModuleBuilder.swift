//
//  ModuleBuilder.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

class ModuleBuilder: BuilderProtocol {
    
    static func createAdminPanelModule() -> UIViewController {
        let viewController = AdminPanelViewController()
        let presenter = AdminPanelPresentor(view: viewController)
        viewController.presenter = presenter
        
        return viewController
    }
}
