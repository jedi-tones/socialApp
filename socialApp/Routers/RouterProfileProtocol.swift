//
//  RouterProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol RouterProfileProtocol: RouterMain {
    var currentPeopleDelegate: CurrentPeopleDataDelegate? { get set }
    var peopleListnerDelegate: PeopleListenerDelegate? { get set }
    var likeDislikeDelegate: LikeDislikeListenerDelegate? { get set }
    var acceptChatsDelegate: AcceptChatListenerDelegate? { get set }
    var requestChatsDelegate: RequestChatListenerDelegate? { get set }
    var reportsDelegate: ReportsListnerDelegate? { get set }
    
    func initialViewController()
    func popToRoot()
    func showAdminPanel()
    func setupProfile()
    func showSetupSearch()
    func showAppSettings()
    func showContacts()
    func showAboutInformation()
    func showPremiumPurchases(viewController: UIViewController)
}
