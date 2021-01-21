//
//  ProfileViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 07.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController, ProfileViewProtocol {
    
    private var refreshControl = UIRefreshControl()
    var collectionView: UICollectionView!
    var presenter: ProfilePresenterProtocol!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCollectionView()
        setupConstraints()
        presenter.setupDataSource()
        presenter.updateDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    private func setup() {
        view.backgroundColor = .myWhiteColor()
        
        navigationItem.backButtonTitle = ""
        navigationItem.largeTitleDisplayMode = .never
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func showPopUpMessage(header: String, text: String) {
        PopUpService.shared.showInfo(text: text)
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
            
            switch cell {
            
            case .setupProfile:
                presenter.setupProfile()
                
            case .setupSearch:
                presenter.showSetupSearch()
                
            case .appSettings:
                presenter.showAppSettings()
                
            case .contacts:
                presenter.showContacts()
                
            case .aboutInformation:
                presenter.showAboutInformation()
                
            case .adminPanel:
                presenter.showAdminPanel()
            default:
                break
            }
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
    }
}

//MARK: objc
extension ProfileViewController {
    @objc private func refresh() {
        presenter.refreshProfile()
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
