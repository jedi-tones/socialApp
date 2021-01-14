//
//  RouterProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol RouterProfileProtocol: RouterMain {
    func initialViewController(currentPeopleDelegate: CurrentPeopleDataDelegate?,
                               peopleListnerDelegate: PeopleListenerDelegate?,
                               likeDislikeDelegate: LikeDislikeListenerDelegate?,
                               acceptChatsDelegate: AcceptChatListenerDelegate?,
                               requestChatsDelegate: RequestChatListenerDelegate?,
                               reportsDelegate: ReportsListnerDelegate)
    func popToRoot()
    func showAdminPanel()
   
}
