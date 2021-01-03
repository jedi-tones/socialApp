//
//  AppSettingsViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 27.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import SDWebImage
import FirebaseMessaging
import ApphudSDK

class AppSettingsViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SectionAppSettings, MAppSettings>?
    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    private weak var acceptChatDelegate: AcceptChatListenerDelegate?
    private weak var requestChatDelegate: RequestChatListenerDelegate?
    private weak var likeDislikeDelegate: LikeDislikeListenerDelegate?
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?,
         acceptChatDelegate: AcceptChatListenerDelegate?,
         requestChatDelegate: RequestChatListenerDelegate?,
         likeDislikeDelegate: LikeDislikeListenerDelegate?) {
        
        self.acceptChatDelegate = acceptChatDelegate
        self.requestChatDelegate = requestChatDelegate
        self.currentPeopleDelegate = currentPeopleDelegate
        self.likeDislikeDelegate = likeDislikeDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        setupNavigationController()
    }
    
    private func setup() {
        view.backgroundColor = .myWhiteColor()
    }
    
    //MARK:  setupNavigationController
    private func setupNavigationController(){
        navigationItem.title = "Настройки"
        navigationItem.backButtonTitle = ""
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension AppSettingsViewController {
    //MARK: deleteAllUserData
    private func deleteAllUserData() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on AppSettingsVC")}
        guard let acceptChatDelegate = acceptChatDelegate else { fatalError("acceptChatDelegate is nil on AppSettingsVC")}
        guard let likeDislikeDelegate = likeDislikeDelegate else { fatalError("likeDislikeDelegate is nil on AppSettingsVC")}
        
        
        Apphud.logout()
        PushMessagingService.shared.logOutUnsabscribe(currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                                      acceptChats: acceptChatDelegate.acceptChats)
        
        //unsubscribe from token pushMessage
        PushMessagingService.shared.deleteToken(currentPeopleID: currentPeopleDelegate.currentPeople.senderId,
                                                acceptChats: acceptChatDelegate.acceptChats,
                                                likeChats: likeDislikeDelegate.likePeople) { result in
            switch result {
            
            case .success():
                FirestoreService.shared.deleteAllProfileData(userID: currentPeopleDelegate.currentPeople.senderId) { [weak self] in
                    //after delete, sign out
                    self?.view.addCustomTransition(type: .fade)
                    AuthService.shared.signOut(currentPeopleDelegate: currentPeopleDelegate) { result in
                        switch result {
                        case .success(_):
                            currentPeopleDelegate.deletePeople()
                        case .failure(let error):
                            fatalError(error.localizedDescription)
                        }
                    }
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

//MARK: setupCollectionView
extension AppSettingsViewController {
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: setupLayout())
        collectionView.backgroundColor = .myWhiteColor()
        collectionView.delegate = self
        
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
    
    //MARK: setupDataSource
    private func setupDataSource() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on AppSettingsVC")}
        
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexpath, item -> UICollectionViewCell? in
                
                guard let cell =  MAppSettings(rawValue: indexpath.item) else { fatalError("Unknown cell")}
                
                switch cell {
                
                case .about:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InfoCell.reuseID, for: indexpath) as? InfoCell else { fatalError("Can't dequeue cell type SettingsCell")}
                    
                    cell.configure(header: "Твой аккаунт", subHeader: currentPeopleDelegate.currentPeople.senderId)
                    return cell
                default:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SettingsCell.reuseID, for: indexpath) as? SettingsCell else { fatalError("Can't dequeue cell type SettingsCell")}
                    
                    cell.configure(settings: item)
                    cell.layoutIfNeeded()
                    return cell
                }
            }
        )
    }
    
    //MARK: updateDataSource
    private func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionAppSettings, MAppSettings>()
        snapshot.appendSections([.appSettings])
        let items = MAppSettings.allCases
        snapshot.appendItems( items, toSection: .appSettings)
        
        dataSource?.apply(snapshot)
    }
}

//MARK: collectionViewDelegate
extension AppSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let section = SectionAppSettings(rawValue: indexPath.section) else { return }
        
        if section == .appSettings {
            guard let cell = MAppSettings(rawValue: indexPath.row ) else { fatalError("unknown cell")}
            
            switch cell {
            
            case .about:
                collectionView.deselectItem(at: indexPath, animated: false)
            case .logOut:
                signOutAlert(pressedIndexPath: indexPath)
            case .terminateAccaunt:
                terminateAccauntAlert(pressedIndexPath: indexPath)
            }
        }
    }
}

//MARK: - ALERTS
extension AppSettingsViewController {
    
    
    //MARK:  signOutAlert
    private func signOutAlert(pressedIndexPath: IndexPath) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { return }
        guard let acceptChatDelegate = acceptChatDelegate else { return }
        guard let likeDislikeDelegate = likeDislikeDelegate else { return }
        
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Выйду, но вернусь",
                                     style: .destructive) {[weak self] _ in
            
            self?.view.addCustomTransition(type: .fade)
            //unsubscribe from topic pushMessage
            PushMessagingService.shared.logOutUnsabscribe(currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                                          acceptChats: acceptChatDelegate.acceptChats)
            
            //unsubscribe from token pushMessage 
            PushMessagingService.shared.deleteToken(currentPeopleID: currentPeopleDelegate.currentPeople.senderId,
                                                    acceptChats: acceptChatDelegate.acceptChats,
                                                    likeChats: likeDislikeDelegate.likePeople) { result in
                switch result {
                
                case .success():
                    AuthService.shared.signOut(currentPeopleDelegate: currentPeopleDelegate) { result in
                        switch result {
                        case .success(_):
                            
                            Apphud.logout()
                            currentPeopleDelegate.deletePeople()
                            
                            
                        case .failure(let error):
                            PopUpService.shared.showInfo(text: "Ошибка: \(error)")
                        }
                    }
                case .failure(let error):
                    PopUpService.shared.showInfo(text: "Ошибка: \(error)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Продолжу общение",
                                         style: .default) { [weak self] _ in
            self?.collectionView.deselectItem(at: pressedIndexPath, animated: true)
        }
        
        alert.setMyLightStyle()
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK:  terminateAccauntAlert
    private func terminateAccauntAlert(pressedIndexPath: IndexPath) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on AppSettingsVC")}
        
        let alert = UIAlertController(title: nil,
                                      message: "Удалить профиль полностью, без возможности восстановления?",
                                      preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ввести пароль и удалить",
                                     style: .destructive) {[weak self] _ in
            
            let authType = currentPeopleDelegate.currentPeople.authType
            
            switch authType {
            case .appleID:
                AuthService.shared.AppleIDRequest(delegateController: self!,
                                                  presetationController: self!)
            case .email:
                self?.emailLoginAlert()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Продолжу общение",
                                         style: .default) { [weak self] _ in
            self?.collectionView.deselectItem(at: pressedIndexPath, animated: true)
        }
        
        alert.setMyLightStyle()
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK:  emailLoginAlert
    private func emailLoginAlert() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil on AppSettingsVC")}
        
        let alert = UIAlertController(title: "Введи свой пароль от почты:",
                                      message: currentPeopleDelegate.currentPeople.mail,
                                      preferredStyle: .alert)

        let actionOK = UIAlertAction(title: "Подтвердить",
                                     style: .cancel) {[weak self] _ in
            
            guard let password = alert.textFields?.first?.text else { return }
            
            AuthService.shared.reAuthentificate(credential: nil,
                                                email: currentPeopleDelegate.currentPeople.mail,
                                                password: password) { result in
                switch result {
                
                case .success(_):
                    self?.deleteAllUserData()
                    
                case .failure(let error):
                    self?.reAuthErrorAlert(text: error.localizedDescription)
                }
            }
        }
        
        alert.addTextField { passwordTextField in
            passwordTextField.isSecureTextEntry = true
            passwordTextField.tag = 1
            passwordTextField.delegate = self
        }
        
        alert.setMyLightStyle()
        alert.addAction(actionOK)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK:  reAuthAlert
    private func reAuthErrorAlert(text: String) {
        let alert = UIAlertController(title: "Ошибка",
                                      message: text,
                                      preferredStyle: .actionSheet)
        let actionCancel = UIAlertAction(title: "Хорошо",
                                         style: .cancel, handler: nil)
        
        alert.setMyLightStyle()
        alert.addAction(actionCancel)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: UITextFieldDelegate
extension AppSettingsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField, nextField.isEnabled {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
}

//MARK: - AppleID Auth
extension AppSettingsViewController: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = self.view.window else { fatalError("can't get window")}
        return window
    }
}

//MARK:  ASAuthorizationControllerDelegate
extension AppSettingsViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        AuthService.shared.didCompleteWithAuthorizationApple(authorization: authorization) {  [weak self] result in
            
            switch result {
            
            //if success get credential, then auth
            case .success(let credential):
                
                AuthService.shared.reAuthentificate(credential: credential, email: nil, password: nil) { result in
                    switch result {
                    
                    case .success(_):
                        //after reAuth, delete all user data
                        self?.deleteAllUserData()
                        
                    case .failure(let error):
                        self?.reAuthErrorAlert(text: error.localizedDescription)
                    }
                }
            //Error get credential for Apple Auth
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

//MARK: setupConstraints
extension AppSettingsViewController {
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


