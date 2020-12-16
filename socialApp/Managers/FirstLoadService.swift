//
//  FirstLoadService.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import ApphudSDK

class FirstLoadService {
    
    //private let currentUser: MPeople
    private var acceptChatsDelegate: AcceptChatListenerDelegate
    private var requestChatsDelegate: RequestChatListenerDelegate
    private var peopleDelegate: PeopleListenerDelegate
    private var likeDislikeDelegate: LikeDislikeListenerDelegate
    private var messageDelegate: MessageListenerDelegate
    private var reportsDelegate: ReportsListnerDelegate
    private var currentPeopleDelegate: CurrentPeopleDataDelegate
    
    init(currentUser: MPeople) {
        //  self.currentUser = currentUser
        likeDislikeDelegate = LikeDislikeChatDataProvider(userID: currentUser.senderId)
        requestChatsDelegate = RequestChatDataProvider(userID: currentUser.senderId)
        acceptChatsDelegate = AcceptChatDataProvider(userID: currentUser.senderId)
        peopleDelegate = PeopleDataProvider(userID: currentUser.senderId)
        messageDelegate = MessagesDataProvider(userID: currentUser.senderId)
        reportsDelegate = ReportsDataProvider(userID: currentUser.senderId)
        currentPeopleDelegate = CurrentPeopleDataProvider(currentPeople: currentUser)
    }
    
    func loadData(complition: @escaping(_ currentPeopleDelegate: CurrentPeopleDataDelegate,
                                        _ acceptChatsDelegate: AcceptChatListenerDelegate,
                                        _ requestChatsDelegate: RequestChatListenerDelegate,
                                        _ peopleDelegate: PeopleListenerDelegate,
                                        _ likeDislikeDelegate: LikeDislikeListenerDelegate,
                                        _ messageDelegate: MessageListenerDelegate,
                                        _ reportsDelegate: ReportsListnerDelegate )->Void) {
        setup()
        setupApphud()
        getPeopleData { [unowned self]  result in
            switch result {
            
            case .success():
                complition(currentPeopleDelegate,
                           acceptChatsDelegate,
                           requestChatsDelegate,
                           peopleDelegate,
                           likeDislikeDelegate,
                           messageDelegate,
                           reportsDelegate)
                
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension FirstLoadService {
    
    private func setup() {
        //update current user in UserDefault
        
        PopUpService.shared.setupDelegate(acceptChatsDelegate: acceptChatsDelegate,
                                          requestChatsDelegate: requestChatsDelegate,
                                          peopleDelegate: peopleDelegate,
                                          likeDislikeDelegate: likeDislikeDelegate,
                                          messageDelegate: messageDelegate,
                                          reportsDelegate: reportsDelegate)
        
    }
    
    private func subscribeToPushNotification() {
        //subscribe to all pushNotification from chats after relogin
        PushMessagingService.shared.logInSubscribe(currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                                   acceptChats: acceptChatsDelegate.acceptChats,
                                                   likeChats: likeDislikeDelegate.likePeople)
        
    }
    
    private func setupApphud() {
        Apphud.start(apiKey: "app_LDXecjNbEuvUBtpd3J9kw75A6cH14n",
                     userID: currentPeopleDelegate.currentPeople.senderId,
                     observerMode: false)
    }
    
    //MARK: getPeopleData, location
    private func getPeopleData(complition:@escaping(Result<(),Error>) -> Void) {
        
        let people = currentPeopleDelegate.currentPeople
        if let virtualLocation = MVirtualLocation(rawValue: people.searchSettings[MSearchSettings.currentLocation.rawValue] ?? 0) {
            LocationService.shared.getCoordinate(userID: people.senderId,
                                                 virtualLocation: virtualLocation) {[unowned self] isAllowPermission in
                //if geo is denied, show alert and go to settings
                if !isAllowPermission {
                    openSettingsAlert()
                }
                //get like users
                likeDislikeDelegate.getLike(complition: { result in
                    switch result {
                    
                    case .success(_):
                        //get dislike users
                        likeDislikeDelegate.getDislike(complition: { result in
                            switch result {
                            
                            case .success(_):
                                //get reports
                                reportsDelegate.getReports(complition: { result in
                                    switch result {
                                    
                                    case .success(_):
                                        //get request users
                                        requestChatsDelegate.getRequestChats(reportsDelegate: reportsDelegate, complition: { result in
                                            switch result {
                                            
                                            case .success(_):
                                                //get accept chats
                                                acceptChatsDelegate.getAcceptChats(complition: { result in
                                                    switch result {
                                                    
                                                    case .success(_):
                                                        
                                                        peopleDelegate.getPeople(currentPeople: people,
                                                                                 likeDislikeDelegate: likeDislikeDelegate,
                                                                                 acceptChatsDelegate: acceptChatsDelegate,
                                                                                 reportsDelegate: reportsDelegate,
                                                                                 complition: { result in
                                                                                    switch result {
                                                                                    
                                                                                    case .success(_):
                                                                                        subscribeToPushNotification()
                                                                                        //check active subscribtion
                                                                                        PurchasesService.shared.checkSubscribtion(currentPeople: people) { _ in
                                                                                            
                                                                                            currentPeopleDelegate.updatePeopleDataFromFirestore { result in
                                                                                                switch result {
                                                                                                
                                                                                                case .success(_):
                                                                                                    complition(.success(()))
                                                                                                case .failure(let error):
                                                                                                    complition(.failure(error))
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    case .failure(let error):
                                                                                        complition(.failure(error))
                                                                                    }
                                                                                 })
                                                        
                                                    case .failure(let error):
                                                        complition(.failure(error))
                                                    }
                                                })
                                                
                                            case .failure(let error):
                                                complition(.failure(error))
                                            }
                                        })
                                        
                                    case .failure(let error):
                                        complition(.failure(error))
                                    }
                                })
                            case .failure(let error):
                                complition(.failure(error))
                            }
                        })
                    case .failure(let error):
                        complition(.failure(error))
                    }
                })
            }
        }
    }
}



//MARK: alert
extension FirstLoadService {
    
    private func openSettingsAlert(){
        PopUpService.shared.bottomPopUp(header: "Нет доступа к геопозиции",
                                        text: "Необходимо разрешить доступ к геопозиции в настройках",
                                        image: nil,
                                        okButtonText: "Перейти в настройки") {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}
