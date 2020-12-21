//
//  MainTabBarController.swift
//  socialApp
//
//  Created by Денис Щиголев on 05.07.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth
import ApphudSDK

class MainTabBarController: UITabBarController{
    
    private var isNewLogin: Bool
    private var dataDelegateService: DataDelegateService
    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    private weak var acceptChatsDelegate: AcceptChatListenerDelegate?
    private weak var requestChatsDelegate: RequestChatListenerDelegate?
    private weak var messageDelegate: MessageListenerDelegate?
    private weak var reportDelegate: ReportsListnerDelegate?
    private weak var peopleDelegate: PeopleListenerDelegate?
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate, isNewLogin: Bool) {
        self.currentPeopleDelegate = currentPeopleDelegate
        self.isNewLogin = isNewLogin
        self.dataDelegateService = DataDelegateService(currentPeopleID: currentPeopleDelegate.currentPeople.senderId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Deinit main tabbar")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupControllers()
        
    }
}

extension MainTabBarController {
    private func setup() {
        if isNewLogin {
            PopUpService.shared.showAnimateView(name: MAnimamationName.loading.rawValue)
        }
        view.backgroundColor = .myWhiteColor()
        
        DeeplinkNavigator.shared.setupDelegate(mainTabBarDelegate: self)
        
        let appearance = tabBar.standardAppearance.copy()
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        appearance.backgroundColor = .myWhiteColor()
        tabBar.standardAppearance = appearance
        
        let appearanceTabBarItem = UITabBarItemAppearance(style: .stacked)
        appearanceTabBarItem.normal.badgeBackgroundColor = .mySecondSatColor()
        appearanceTabBarItem.normal.badgeTextAttributes = [NSAttributedString.Key.font : UIFont.avenirBold(size: 11)]
        appearanceTabBarItem.selected.badgeBackgroundColor = .mySecondSatColor()
        appearanceTabBarItem.selected.badgeTextAttributes = [NSAttributedString.Key.font : UIFont.avenirBold(size: 11)]
        
        tabBar.standardAppearance.stackedLayoutAppearance = appearanceTabBarItem
        
        tabBar.unselectedItemTintColor = .myLightGrayColor()
        tabBar.tintColor = .myLabelColor()
    }
    
   
}

//MARK: - MainTabBarDelegate
extension MainTabBarController: MainTabBarDelegate {
    func renewBadge() {
        guard let acceptChatDelegate = acceptChatsDelegate,
              let requestChatDelegate = requestChatsDelegate else { return }
        
        acceptChatsDelegate?.mainTabBarDelegate = self
        requestChatsDelegate?.mainTabBarDelegate = self
        
        tabBar.items?.forEach({ item in
            switch item.tag {
            case 2:
                //requests
                let count = requestChatDelegate.requestChats.count
                
                if count == .zero {
                    item.badgeValue = nil
                } else {
                    item.badgeValue = String(count)
                }
    
            case 3:
                //chats
                let count = acceptChatDelegate.calculateUnreadAndNewChats()
                if count == .zero {
                    item.badgeValue = nil
                } else {
                    item.badgeValue = String(count)
                }
                
            default:
                break
            }
        })
    }
    
    //MARK: showChatWith
    func showChatWith(friendID: String) {
        
        guard let chat = acceptChatsDelegate?.acceptChats.first(where: { $0.friendId == friendID}),
              let selectedVC = selectedViewController,
              let navVC = selectedVC as? NavigationControllerWithComplition,
              let visibleVC = navVC.visibleViewController else { return  }
        //if this chat, don't already open
        print("\n lastselect \(acceptChatsDelegate?.lastSelectedChat?.friendId )")
        print("\n needShow \(friendID )")
        guard acceptChatsDelegate?.lastSelectedChat?.friendId != friendID else { return }
        
        let chatVC = ChatViewController(currentPeopleDelegate: currentPeopleDelegate,
                                        chat: chat,
                                        messageDelegate: messageDelegate,
                                        acceptChatDelegate: acceptChatsDelegate,
                                        reportDelegate: reportDelegate,
                                        peopleDelegate: peopleDelegate,
                                        requestDelegate: requestChatsDelegate)
        
        if navVC.viewControllers.first != visibleVC {
            navVC.popToRootViewController(animated: false) {
                navVC.pushViewController(chatVC, animated: true)
            }
        } else {
            navVC.pushViewController(chatVC, animated: true)
        }
    }
}

//MARK: - setupControllers
extension MainTabBarController {
    
    private func setupControllers(){
        guard let newCurrentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in MainTabBarVC")}
        
        
        dataDelegateService.loadData(currentPeople: newCurrentPeopleDelegate.currentPeople) {[unowned self] acceptChatsDelegate,
                                                                                                            requestChatsDelegate,
                                                                                                            peopleDelegate,
                                                                                                            likeDislikeDelegate,
                                                                                                            messageDelegate,
                                                                                                            reportsDelegate in
            
            
            
            self.acceptChatsDelegate = acceptChatsDelegate
            self.requestChatsDelegate = requestChatsDelegate
            self.messageDelegate = messageDelegate
            self.reportDelegate = reportsDelegate
            self.peopleDelegate = peopleDelegate
            
            
            let profileVC = ProfileViewController(currentPeopleDelegate: newCurrentPeopleDelegate,
                                                  peopleListnerDelegate: peopleDelegate,
                                                  likeDislikeDelegate: likeDislikeDelegate,
                                                  acceptChatsDelegate: acceptChatsDelegate,
                                                  requestChatsDelegate: requestChatsDelegate,
                                                  reportsDelegate: reportsDelegate)
            
            let peopleVC = PeopleViewController(currentPeopleDelegate: newCurrentPeopleDelegate,
                                                peopleDelegate: peopleDelegate,
                                                requestChatDelegate: requestChatsDelegate,
                                                likeDislikeDelegate: likeDislikeDelegate,
                                                acceptChatDelegate: acceptChatsDelegate,
                                                reportDelegate: reportsDelegate)
            
            peopleDelegate.peopleCollectionViewDelegate = peopleVC
            
            let requsetsVC = RequestsViewController(currentPeopleDelegate: newCurrentPeopleDelegate,
                                                    likeDislikeDelegate: likeDislikeDelegate,
                                                    requestChatDelegate: requestChatsDelegate,
                                                    peopleNearbyDelegate: peopleDelegate,
                                                    acceptChatDelegate: acceptChatsDelegate,
                                                    reportDelegate: reportsDelegate)
            
            requestChatsDelegate.requestChatCollectionViewDelegate = requsetsVC
            
            let chatsVC = ChatsViewController(currentPeopleDelegate: newCurrentPeopleDelegate,
                                              acceptChatDelegate: acceptChatsDelegate,
                                              likeDislikeDelegate: likeDislikeDelegate,
                                              messageDelegate: messageDelegate,
                                              requestChatsDelegate: requestChatsDelegate,
                                              peopleDelegate: peopleDelegate,
                                              reportDelegate: reportsDelegate)
            
            acceptChatsDelegate.acceptChatCollectionViewDelegate = chatsVC
            
            
            
            viewControllers = [
                generateNavigationController(rootViewController: peopleVC, image: #imageLiteral(resourceName: "people"), title: nil, tag: 1, isHidden: true),
                generateNavigationController(rootViewController: requsetsVC, image: #imageLiteral(resourceName: "request"), title: nil, tag: 2, isHidden: true),
                generateNavigationController(rootViewController: chatsVC, image: #imageLiteral(resourceName: "chats"), title: nil, tag: 3),
                generateNavigationController(rootViewController: profileVC, image: #imageLiteral(resourceName: "profile"), title: nil, tag: 4,  isHidden: true)
            ]
            PopUpService.shared.dismisPopUp(name: MAnimamationName.loading.rawValue) {}
            //renew tabBar badge after load all VC
            renewBadge()
            
        }
    }
    
    //MARK: generateNavigationController
    private func generateNavigationController(rootViewController: UIViewController,
                                              image: UIImage,
                                              title: String?,
                                              tag: Int,
                                              isHidden: Bool = false,
                                              withoutBackImage: Bool = false) -> UIViewController {
        
        let navController = NavigationControllerWithComplition(rootViewController: rootViewController)
        navController.tabBarItem.imageInsets = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        navController.tabBarItem.image = image
        navController.tabBarItem.tag = tag
        navController.navigationItem.title = title
        navController.navigationBar.isHidden = isHidden
        
        let appereance = navController.navigationBar.standardAppearance.copy()
        appereance.shadowImage = UIImage()
        appereance.shadowColor = .clear
        appereance.backgroundImage = UIImage()
        appereance.backgroundColor = .myWhiteColor()
        
        navController.navigationBar.standardAppearance = appereance
        navController.navigationBar.prefersLargeTitles = false
        navController.navigationBar.tintColor = .myLabelColor()
        
        navController.navigationBar.titleTextAttributes = [.font: UIFont.avenirBold(size: 16)]
        navController.navigationBar.largeTitleTextAttributes = [.font: UIFont.avenirBold(size: 38)]
        return navController
    }
}


