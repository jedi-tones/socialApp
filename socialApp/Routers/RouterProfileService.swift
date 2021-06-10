//
//  RouterService.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

class RouterProfileService: RouterProfileProtocol {
    
    var currentPeopleDelegate: CurrentPeopleDataDelegate?
    
    weak var peopleListnerDelegate: PeopleListenerDelegate?
    weak var likeDislikeDelegate: LikeDislikeListenerDelegate?
    weak var acceptChatsDelegate: AcceptChatListenerDelegate?
    weak var requestChatsDelegate: RequestChatListenerDelegate?
    weak var reportsDelegate: ReportsListnerDelegate?
    
    var navigationController: UINavigationController?
    var moduleBuilder: BuilderProtocol?
    
    init(navigationController: UINavigationController?,
         moduleBuilder: BuilderProtocol?) {
        self.navigationController = navigationController
        self.moduleBuilder = moduleBuilder
        
    }
    
    func initialViewController() {
        guard let currentPeopleDelegate =  currentPeopleDelegate else { fatalError("Current people is nil")}
        if let navigationController = navigationController {
            guard let profileViewController = moduleBuilder?.createProfileModule(
                    currentPeopleDelegate: currentPeopleDelegate,
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
    
    func setupProfile() {
        //need change to MVP
        let vc = EditProfileViewController(currentPeopleDelegate: currentPeopleDelegate)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showSetupSearch() {
        //need change to MVP
        let vc = EditSearchSettingsViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                  peopleListnerDelegate: peopleListnerDelegate,
                                                  likeDislikeDelegate: likeDislikeDelegate,
                                                  acceptChatsDelegate: acceptChatsDelegate,
                                                  reportsDelegate: reportsDelegate)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showAppSettings() {
        //need change to MVP
        let vc = AppSettingsViewController(currentPeopleDelegate: currentPeopleDelegate,
                                           acceptChatDelegate: acceptChatsDelegate,
                                           requestChatDelegate: requestChatsDelegate,
                                           likeDislikeDelegate: likeDislikeDelegate)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showContacts() {
        //need change to MVP
        let contactsVC = ContactsViewController()
        contactsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(contactsVC, animated: true)
    }
    
    func showAboutInformation() {
        //need change to MVP
        let aboutVC = AboutViewController()
        aboutVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(aboutVC, animated: true)
    }
    
    func showPremiumPurchases(viewController: UIViewController) {
        //need change to MVP
        
        let purchasVC = PurchasesViewController(currentPeopleDelegate: currentPeopleDelegate)
        purchasVC.modalPresentationStyle = .fullScreen
        viewController.present(purchasVC, animated: true, completion: nil)
        
    }
    
}
