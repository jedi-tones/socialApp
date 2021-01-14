//
//  RouterService.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

class RouterProfileService: RouterProfileProtocol {
    var navigationController: UINavigationController?
    var moduleBuilder: BuilderProtocol?
    
    init(navigationController: UINavigationController?, moduleBuilder: BuilderProtocol?) {
        self.navigationController = navigationController
        self.moduleBuilder = moduleBuilder
    }
    
    func initialViewController(currentPeopleDelegate: CurrentPeopleDataDelegate?,
                               peopleListnerDelegate: PeopleListenerDelegate?,
                               likeDislikeDelegate: LikeDislikeListenerDelegate?,
                               acceptChatsDelegate: AcceptChatListenerDelegate?,
                               requestChatsDelegate: RequestChatListenerDelegate?,
                               reportsDelegate: ReportsListnerDelegate) {
        
        if let navigationController = navigationController {
            guard let profileViewController = moduleBuilder?.createProfileModule(
                    currentPeopleDelegate: currentPeopleDelegate,
                    peopleListnerDelegate: peopleListnerDelegate,
                    likeDislikeDelegate: likeDislikeDelegate,
                    acceptChatsDelegate: acceptChatsDelegate,
                    requestChatsDelegate: requestChatsDelegate,
                    reportsDelegate: reportsDelegate,
                    router: self) else { return }
            navigationController.viewControllers = [profileViewController]
        }
    }
    
    func popToRoot() {
        if let navigationController = navigationController {
            navigationController.popToRootViewController(animated: true)
        }
    }
    
    func showAdminPanel() {
        if let navigationController = navigationController {
            guard let adminPanelViewController = moduleBuilder?.createAdminPanelModule(router: self) else { return }
            navigationController.pushViewController(adminPanelViewController, animated: true)
        }
    }
       
}
