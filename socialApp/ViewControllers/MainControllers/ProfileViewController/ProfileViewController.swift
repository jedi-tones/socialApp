//
//  ProfileViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 07.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    weak var peopleListnerDelegate: PeopleListenerDelegate?
    weak var likeDislikeDelegate: LikeDislikeListenerDelegate?
    weak var acceptChatsDelegate: AcceptChatListenerDelegate?
    weak var requestChatsDelegate: RequestChatListenerDelegate?
    weak var reportsDelegate: ReportsListnerDelegate?
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SectionsProfile, MProfileSettings>?
    private var refreshControl = UIRefreshControl()
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?,
         peopleListnerDelegate: PeopleListenerDelegate?,
         likeDislikeDelegate: LikeDislikeListenerDelegate?,
         acceptChatsDelegate: AcceptChatListenerDelegate?,
         requestChatsDelegate: RequestChatListenerDelegate?,
         reportsDelegate: ReportsListnerDelegate) {
        
        self.currentPeopleDelegate = currentPeopleDelegate
        self.peopleListnerDelegate = peopleListnerDelegate
        self.likeDislikeDelegate = likeDislikeDelegate
        self.acceptChatsDelegate = acceptChatsDelegate
        self.requestChatsDelegate = requestChatsDelegate
        self.reportsDelegate = reportsDelegate
        super.init(nibName: nil, bundle: nil)
        setupNotification()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCollectionView()
        setupConstraints()
        setupDataSource()
        updateDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      //  updateSections()
      //  updateCurrentPeople()
    }
    
    private func setup() {
        view.backgroundColor = .myWhiteColor()
        
        navigationItem.backButtonTitle = ""
        navigationItem.largeTitleDisplayMode = .never
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupNotification() {
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(updateSections))
        NotificationCenter.addObsorverToPremiumUpdate(observer: self, selector: #selector(updateSections))
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

//MARK: setupCollectionView
extension ProfileViewController {
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setupLayout())
        
        collectionView.backgroundColor = .myWhiteColor()
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: ProfileCell.reuseID)
        collectionView.register(SettingsCell.self, forCellWithReuseIdentifier: SettingsCell.reuseID)
        collectionView.register(PremiumCell.self, forCellWithReuseIdentifier: PremiumCell.reuseID)
    }
    
    private func setupProfileSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 20,
                                                        bottom: 0,
                                                        trailing: 20)
        
        return section
    }
    
     private func setupPremiumSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(170))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(170))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 20,
                                                        bottom: 25,
                                                        trailing: 20)
        
        return section
    }
    
    private func setupSettingsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(50))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 20,
                                                        bottom: 0,
                                                        trailing: 20)
        
        return section
    }
    
    //MARK: setupLayout
    private func setupLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {[weak self] section, environment -> NSCollectionLayoutSection? in
            guard let section = SectionsProfile(rawValue: section) else { fatalError("Unknow section")}
            
            switch section {
            case .profile:
                return self?.setupProfileSection()
            case .premium:
                return self?.setupPremiumSection()
            case .settings:
                return self?.setupSettingsSection()
            }
        }
        return layout
    }
    
    //MARK: setupDataSource
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView,
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
    
    //MARK: updateProfileSection
    @objc private func updateSections() {
        
        guard var snapshot = dataSource?.snapshot() else { return }
        snapshot.reloadSections([ .profile, .premium])
        
        dataSource?.apply(snapshot,animatingDifferences: true)
    }
    
    //MARK: updateDataSource
    private func updateDataSource() {
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
}

//MARK: collectionViewDelegate
extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let section = SectionsProfile(rawValue: indexPath.section) else { return }
        switch section {
        
        case .profile:
            return
            
        case .premium:
           return
            
        case .settings:
            let firstIndexOfSettingsInProfileSettings = 2
            guard let cell = MProfileSettings(rawValue: indexPath.item + firstIndexOfSettingsInProfileSettings) else { fatalError("unknown cell")}
            guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on ProfileViewController")}
            
            switch cell {
            
            case .setupProfile:
                let vc = EditProfileViewController(currentPeopleDelegate: currentPeopleDelegate)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
                
                collectionView.deselectItem(at: indexPath, animated: true)
                
            case .setupSearch:
                let vc = EditSearchSettingsViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                          peopleListnerDelegate: peopleListnerDelegate,
                                                          likeDislikeDelegate: likeDislikeDelegate,
                                                          acceptChatsDelegate: acceptChatsDelegate,
                                                          reportsDelegate: reportsDelegate)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
                
                collectionView.deselectItem(at: indexPath, animated: true)
                
            case .appSettings:
                let vc = AppSettingsViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                   acceptChatDelegate: acceptChatsDelegate,
                                                   requestChatDelegate: requestChatsDelegate)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
                
                collectionView.deselectItem(at: indexPath, animated: true)
            case .contacts:
                let contactsVC = ContactsViewController()
                contactsVC.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(contactsVC, animated: true)
                
                collectionView.deselectItem(at: indexPath, animated: true)
            case .aboutInformation:
               
               
                let aboutVC = AboutViewController()
                aboutVC.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(aboutVC, animated: true)

                collectionView.deselectItem(at: indexPath, animated: true)
            case .adminPanel:
                break
            default:
                break
            }
        }
        
    }
}

//MARK: objc
extension ProfileViewController {
    @objc private func refresh() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on ProfileViewVC")}
        currentPeopleDelegate.updatePeopleDataFromFirestore(userID: currentPeopleDelegate.currentPeople.senderId,
                                                            complition: {[weak self] result in
                                                                switch result {
            
            case .success(let updatedCurrentPeople):
                self?.collectionView.refreshControl?.endRefreshing()
                PurchasesService.shared.checkSubscribtion(currentPeople: updatedCurrentPeople) { result in
                    switch result {
                    
                    case .success(_):
                    self?.updateSections()
                        
                    case .failure(let error):
                    PopUpService.shared.showInfo(text: "Ошибка: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                PopUpService.shared.showInfo(text: "Ошибка: \(error.localizedDescription)")
            }
        })
    }
    
    @objc private func tapPremiumCell() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on ProfileViewController")}
        
        let purchasVC = PurchasesViewController(currentPeopleDelegate: currentPeopleDelegate)
        purchasVC.modalPresentationStyle = .fullScreen
        present(purchasVC, animated: true, completion: nil)
    }
}
//MARK: setupConstraints
extension ProfileViewController {
    private func setupConstraints() {
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
