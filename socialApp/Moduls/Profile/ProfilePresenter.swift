//
//  ProfilePresenter.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

class ProfilePresenter: ProfilePresenterProtocol {
   
    private weak var view: ProfileViewProtocol?
    private var router: RouterProfileProtocol?
    
    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    var dataSource: UICollectionViewDiffableDataSource<SectionsProfile, MProfileSettings>?
    
    required init(view: ProfileViewProtocol,
         currentPeopleDelegate: CurrentPeopleDataDelegate?,
         router: RouterProfileProtocol) {
        self.view = view
        self.router = router
        self.currentPeopleDelegate = currentPeopleDelegate
        setupNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNotification() {
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(updateSections))
        NotificationCenter.addObsorverToPremiumUpdate(observer: self, selector: #selector(updateSections))
    }
    
    //MARK: setupDataSource
    func setupDataSource() {
        guard let view = view else { return }
        
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: view.collectionView,
            cellProvider: {[weak self] collectionView, indexpath, item -> UICollectionViewCell? in
                
                guard let section = SectionsProfile(rawValue: indexpath.section) else { fatalError("Unknown section")}
                
                switch section {
                
                case .profile:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileCell.reuseID, for: indexpath) as? ProfileCell else { fatalError("Can't dequeue cell type ProfileCell")}
                    
                    cell.configure(people: self?.currentPeopleDelegate?.currentPeople)
                    cell.layoutIfNeeded()
                    return cell
                    
                case .premium:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PremiumCell.reuseID, for: indexpath) as? PremiumCell else { fatalError("Can't dequeue cell type PremiumCell")}
                    guard let currentPeople = self?.currentPeopleDelegate?.currentPeople else { fatalError("current people is nil")}
                    
                    cell.configure(currentUser: currentPeople, tapSelector: #selector(self?.tapPremiumCell), delegate: self)
                    return cell
                    
                case .settings:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsCell.reuseID, for: indexpath) as? SettingsCell else { fatalError("Can't dequeue cell type SettingsCell")}
                    
                    cell.configure(settings: item)
                    return cell
                }
            }
        )
    }
    
    //MARK: updateDataSource
    func updateDataSource() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on ProfileViewController")}
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionsProfile, MProfileSettings>()
        snapshot.appendSections([.profile, .premium, .settings])
        snapshot.appendItems([MProfileSettings.profileInfo], toSection: .profile)
        snapshot.appendItems([MProfileSettings.premiumButton], toSection: .premium)
        snapshot.appendItems([MProfileSettings.setupProfile,
                              MProfileSettings.setupSearch,
                              MProfileSettings.appSettings,
                              MProfileSettings.contacts,
                              MProfileSettings.aboutInformation],
                             toSection: .settings)
        if currentPeopleDelegate.currentPeople.isAdmin {
            snapshot.appendItems([MProfileSettings.adminPanel], toSection: .settings)
        }
        dataSource?.apply(snapshot)
    }
    
    //MARK: refreshProfile
    func refreshProfile() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on ProfilePresenter")}
        currentPeopleDelegate.updatePeopleDataFromFirestore(
            userID: currentPeopleDelegate.currentPeople.senderId,
            complition: {[weak self] result in
                switch result {
                
                case .success(let updatedCurrentPeople):
                    self?.view?.collectionView.refreshControl?.endRefreshing()
                    PurchasesService.shared.checkSubscribtion(currentPeople: updatedCurrentPeople) { result in
                        switch result {
                        
                        case .success(_):
                            self?.updateSections()
                            
                        case .failure(let error):
                            self?.view?.showPopUpMessage(header: "", text: "Ошибка: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    self?.view?.showPopUpMessage(header: "", text: "Ошибка: \(error.localizedDescription)")
                }
            })
    }
    
    func setupProfile() {
        router?.setupProfile()
    }
    
    func showSetupSearch() {
        router?.showSetupSearch()
    }
    
    func showAppSettings() {
        router?.showAppSettings()
    }
    
    func showContacts() {
        router?.showContacts()
    }
    
    func showAboutInformation() {
        router?.showAboutInformation()

    }
    
    func showAdminPanel() {
        router?.showAdminPanel()
    }
    
    func showPremiumPurchases() {
        guard let view = view else { return }
        router?.showPremiumPurchases(viewController: view)
    }
    
    //MARK: updateSections
    @objc private func updateSections() {
        guard var snapshot = dataSource?.snapshot() else { return }
        snapshot.reloadSections([.profile, .premium])
        dataSource?.apply(snapshot,animatingDifferences: true)
    }
    
    @objc private func tapPremiumCell() {
        showPremiumPurchases()
    }
}
