//
//  RequestChatDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 29.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class RequestChatDataProvider: RequestChatListenerDelegate {
    
    var userID: String
    var requestChats: [MChat] = [] {
        didSet {
            sortedRequestChats = requestChats.sorted {
                $0.date > $1.date
            }
            mainTabBarDelegate?.renewBadge()
            sendNotification()
        }
    }
    var sortedRequestChats: [MChat] = []
    
   weak var mainTabBarDelegate: MainTabBarDelegate?
   weak var requestChatCollectionViewDelegate: RequestChatCollectionViewDelegate?
   
    init(userID: String) {
        self.userID = userID
    }
    
    private func sendNotification() {
        NotificationCenter.postRequestCountIsChange(requestCount: requestChats.count)
    }
}

extension RequestChatDataProvider {
    
    //MARK: setup listner
    func setupListener(reportsDelegate: ReportsListnerDelegate) {
        
        ListenerService.shared.addRequestChatsListener(userID: userID,
                                                       requestChatDelegate: self,
                                                       reportsDelegate: reportsDelegate)
    }
    
    //MARK: remove listner
    func removeListener() {
        ListenerService.shared.removeRequestChatsListener()
    }
    
    //MARK: reload listner
    func reloadListener(currentPeople: MPeople,
                        reportsDelegate: ReportsListnerDelegate) {
        requestChats = []
        requestChatCollectionViewDelegate?.reloadData()
        //reload request listner
        removeListener()
        setupListener(reportsDelegate: reportsDelegate)
    }
    
    //MARK: reloadData
    func reloadData(changeType: MTypeOfListenerChanges) {
        if changeType == .add {
            PopUpService.shared.showInfo(text: MLabels.newRequest.rawValue)
        }
        requestChatCollectionViewDelegate?.reloadData()
    }
    
}

extension RequestChatDataProvider {
    //MARK:  get requestChats
    func getRequestChats(reportsDelegate: ReportsListnerDelegate, complition: @escaping (Result<[MChat], Error>) -> Void) {
        
        FirestoreService.shared.getUserCollection(userID: userID,
                                                  collection: MFirestorCollection.requestsChats) {[weak self] result in
            switch result {
            
            case .success(let requests):
                let filtredRequests = requests.filter { requestChat -> Bool in
                    //if request chat don't contains in report list
                    !reportsDelegate.reports.contains { report -> Bool in
                        report.reportUserID == requestChat.friendId
                    }
                }
                self?.requestChats = filtredRequests
                complition(.success(filtredRequests))
                
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
    
    //delete request
    func deleteRequest(requestID: String) {
        let requestIndex = requestChats.firstIndex { currentRequest -> Bool in
            currentRequest.friendId == requestID
        }
        guard let index = requestIndex else { return }
        requestChats.remove(at: index)
        requestChatCollectionViewDelegate?.reloadData()
    }
}
