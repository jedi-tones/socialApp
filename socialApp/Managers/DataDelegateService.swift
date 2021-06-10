//
//  FirstLoadService.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import ApphudSDK

class DataDelegateService {
    
    private var acceptChatsDelegate: AcceptChatListenerDelegate?
    private var requestChatsDelegate: RequestChatListenerDelegate?
    private var peopleDelegate: PeopleListenerDelegate?
    private var likeDislikeDelegate: LikeDislikeListenerDelegate?
    private var messageDelegate: MessageListenerDelegate?
    private var reportsDelegate: ReportsListnerDelegate?
    private var currentPeopleID: String
    
    init(currentPeopleID: String) {
        self.currentPeopleID = currentPeopleID
        likeDislikeDelegate = LikeDislikeChatDataProvider(userID: currentPeopleID)
        requestChatsDelegate = RequestChatDataProvider(userID: currentPeopleID)
        acceptChatsDelegate = AcceptChatDataProvider(userID: currentPeopleID)
        peopleDelegate = PeopleDataProvider(userID: currentPeopleID)
        messageDelegate = MessagesDataProvider(userID: currentPeopleID)
        reportsDelegate = ReportsDataProvider(userID: currentPeopleID)
    }
    
    deinit {
        print("deinit DataDelegateService")
        likeDislikeDelegate = nil
        requestChatsDelegate = nil
        acceptChatsDelegate = nil
        peopleDelegate = nil
        messageDelegate = nil
        reportsDelegate = nil
    }
    
    func loadData(currentPeople: MPeople, complition: @escaping(_ acceptChatsDelegate: AcceptChatListenerDelegate,
                                                                _ requestChatsDelegate: RequestChatListenerDelegate,
                                                                _ peopleDelegate: PeopleListenerDelegate,
                                                                _ likeDislikeDelegate: LikeDislikeListenerDelegate,
                                                                _ messageDelegate: MessageListenerDelegate,
                                                                _ reportsDelegate: ReportsListnerDelegate )->Void) {
        guard let acceptChatsDelegate = acceptChatsDelegate,
              let requestChatsDelegate = requestChatsDelegate,
              let peopleDelegate = peopleDelegate,
              let likeDislikeDelegate = likeDislikeDelegate,
              let messageDelegate = messageDelegate,
              let reportsDelegate = reportsDelegate else { return }
        
        setup()
        setupApphud()
        getPeopleData(people: currentPeople) { result in
            switch result {
            
            case .success():

                complition(acceptChatsDelegate,
                           requestChatsDelegate,
                           peopleDelegate,
                           likeDislikeDelegate,
                           messageDelegate,
                           reportsDelegate)
                
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        NotificationCenter.addObsorverToFCMKeyInChatsUpdate(observer: self, selector: #selector(fcmKeyInChatsUpdate(notification:)))
    }
}

extension DataDelegateService {
    
    //MARK: setup
    private func setup() {
        //update current user in UserDefault
        
        PopUpService.shared.setupDelegate(acceptChatsDelegate: acceptChatsDelegate,
                                          requestChatsDelegate: requestChatsDelegate,
                                          peopleDelegate: peopleDelegate,
                                          likeDislikeDelegate: likeDislikeDelegate,
                                          messageDelegate: messageDelegate,
                                          reportsDelegate: reportsDelegate)
        
    }
    
    //MARK: setupApphud
    private func setupApphud() {
        PurchasesService.shared.apphudUpdateUserID(id: currentPeopleID)
        PurchasesService.shared.getProductsFromApphud()
    }
    
    private func updateFCMKey() {
        PushMessagingService.shared.getToken()
    }
    
    //MARK: fcmKeyInChatsUpdate
    //update fcmKey in chats
    @objc private func fcmKeyInChatsUpdate(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String : String],
              let fcmKey = userInfo[PushMessagingService.shared.notificationName],
              let acceptChatsDelegate = acceptChatsDelegate else { return }
        FirestoreService.shared.updateFCMKeyInChats(id: currentPeopleID,
                                                    fcmKey: fcmKey,
                                                    acceptChats: acceptChatsDelegate.acceptChats) { result in
            switch result {
                
            case .success(_):
                break
            case .failure(let error):
                PopUpService.shared.showInfo(text: "Ошибка \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: getPeopleData, location
    private func getPeopleData(people: MPeople, complition:@escaping(Result<(),Error>) -> Void) {
       
        guard let likeDislikeDelegate = likeDislikeDelegate,
              let reportsDelegate = reportsDelegate,
              let requestChatsDelegate = requestChatsDelegate,
              let acceptChatsDelegate = acceptChatsDelegate,
              let peopleDelegate = peopleDelegate else { return }
              
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
                                                        updateFCMKey()
                                                        peopleDelegate.getPeople(currentPeople: people,
                                                                                 likeDislikeDelegate: likeDislikeDelegate,
                                                                                 acceptChatsDelegate: acceptChatsDelegate,
                                                                                 reportsDelegate: reportsDelegate,
                                                                                 complition: { result in
                                                                                    switch result {
                                                                                    
                                                                                    case .success(_):
                                                                                        
                                                                                        //set complition before check subscribstion, for load screen, when Apphud API offline
                                                                                        complition(.success(()))
                                                                                        //check active subscribtion
                                                                                        PurchasesService.shared.checkSubscribtion(currentPeople: people) { _ in }
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
extension DataDelegateService {
    
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
