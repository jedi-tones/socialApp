//
//  ProfilePresenterProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol ProfilePresenterProtocol: class {
    
    var currentPeopleDelegate: CurrentPeopleDataDelegate? { get }
    var dataSource: UICollectionViewDiffableDataSource<SectionsProfile, MProfileSettings>? { get set }
    
    init(view: ProfileViewProtocol,
         currentPeopleDelegate: CurrentPeopleDataDelegate?,
         router: RouterProfileProtocol)
    
    func setupNotification()
    func setupDataSource()
    func updateDataSource()
    func refreshProfile()
    
    func setupProfile()
    func showSetupSearch()
    func showAppSettings()
    func showContacts()
    func showAboutInformation()
    func showAdminPanel()
    func showPremiumPurchases()

}
