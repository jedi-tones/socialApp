//
//  MainTabBarDelegate.swift
//  socialApp
//
//  Created by Денис Щиголев on 20.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

protocol MainTabBarDelegate: class {
    func renewBadge()
    func showChatWith(friendID: String)
}
