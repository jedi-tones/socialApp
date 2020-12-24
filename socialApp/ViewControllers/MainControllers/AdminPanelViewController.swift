//
//  AdminPanelViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 23.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class AdminPanelViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupCollectionView()
        setupConstraints()
    }
}


extension AdminPanelViewController {
    private func setup(){
        navigationItem.title = "Админ панель"
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //MARK: setupCollectionView
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setupLayout())
        collectionView.backgroundColor = .myWhiteColor()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(SettingsCell.self, forCellWithReuseIdentifier: SettingsCell.reuseID)
        collectionView.register(InfoCell.self, forCellWithReuseIdentifier: InfoCell.reuseID)
    }
    
    private func setupAppSettingsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(50))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 25,
                                                        bottom: 0,
                                                        trailing: 25)
        
        return section
    }
    
    //MARK: setupLayout
    private func setupLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {[weak self] section, environment -> NSCollectionLayoutSection? in
            guard let section = SectionAppSettings(rawValue: section) else { fatalError("Unknow section")}
            
            switch section {
            case .appSettings:
                return self?.setupAppSettingsSection()
            }
        }
        return layout
    }
}

//MARK: UICollectionViewDelegate
extension AdminPanelViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let selected =  MAdminPanelSettings(rawValue: indexPath.item) else { return }
        
        switch selected {
        
        case .info:
            break
        case .settings:
            break
        case .backupAllUsers:
            FirestoreService.shared.backupAllusers { result in
                switch result {
                
                case .success(let peopleId):
                    PopUpService.shared.bottomPopUp(header: "Backup complite",
                                                    text: "complite \(peopleId.count) users",
                                                    image: nil,
                                                    okButtonText: "Ok") {}
                case .failure(let error):
                    PopUpService.shared.bottomPopUp(header: "Backup error",
                                                    text: error.localizedDescription,
                                                    image: nil,
                                                    okButtonText: "Ok") {}
                }
            }
        case .updateGeoHash:
            FirestoreService.shared.updateGeoHashForAllUSer { result in
                switch result {
                
                case .success(let peopleId):
                    PopUpService.shared.bottomPopUp(header: "geoHash update complite",
                                                    text: "complite \(peopleId.count) users",
                                                    image: nil,
                                                    okButtonText: "Ok") {}
                case .failure(let error):
                    PopUpService.shared.bottomPopUp(header: "Backup error",
                                                    text: error.localizedDescription,
                                                    image: nil,
                                                    okButtonText: "Ok") {}
                }
            }
        }
    }
}


//MARK: UICollectionViewDataSource
extension AdminPanelViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        MAdminPanelSettings.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let adminCellModel =  MAdminPanelSettings(rawValue: indexPath.item) else { return UICollectionViewCell() }
        
        switch adminCellModel {
        
        
        case .info:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InfoCell.reuseID, for: indexPath) as? InfoCell else { fatalError()}
            
            cell.configure(header: adminCellModel.description(), subHeader: "Количество пользователей")
            return cell
        case .settings:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsCell.reuseID, for: indexPath) as? SettingsCell else { fatalError()}
            
            cell.configure(settings: adminCellModel)
            return cell
        case .backupAllUsers:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsCell.reuseID, for: indexPath) as? SettingsCell else { fatalError()}
            
            cell.configure(settings: adminCellModel)
            return cell
        case .updateGeoHash:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsCell.reuseID, for: indexPath) as? SettingsCell else { fatalError()}
            
            cell.configure(settings: adminCellModel)
            return cell
        }
    }
}

//MARK: setupConstraints
extension AdminPanelViewController {
    private func setupConstraints() {
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
