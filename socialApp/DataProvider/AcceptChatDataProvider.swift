//
//  AcceptChatDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 29.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class AcceptChatDataProvider: AcceptChatListenerDelegate {
    
    let requestChatsCountName = "RequestChatsCount"
    let staticCellCount = 1
    
    var userID: String
    private var realmAcceptChats: [MChatRealm] = []
    var acceptChats: [MChat] = [] {
        didSet {
            mainTabBarDelegate?.renewBadge()
        }
    }
    var sortedAcceptChats: [MChat] {
        let accept = acceptChats.sorted {
            $0.date > $1.date
        }
        return accept
    }
    var lastSelectedChat: MChat?
    var lastMessageInSelectedChat: MMessage?
     
    weak var acceptChatCollectionViewDelegate: AcceptChatCollectionViewDelegate?
    weak var mainTabBarDelegate: MainTabBarDelegate? 
    weak var messageCollectionViewDelegate: MessageControllerDelegate? {
        didSet {
            if let selectedMessageCollectionView = messageCollectionViewDelegate {
                BackgroundTaskManager.shared.acceptChatDelegate = self
                lastSelectedChat = selectedMessageCollectionView.chat
                chatWasOpenClose(isWasOpen: true,
                                 lastMessage: selectedMessageCollectionView.lastMessage,
                                 chat: lastSelectedChat)
            } else {
                chatWasOpenClose(isWasOpen: false,
                                 lastMessage: lastMessageInSelectedChat,
                                 chat: lastSelectedChat)
            }
        }
    }
    
    init(userID: String) {
        self.userID = userID
        createRequestCountChat()
        configure()
    }
    
    deinit {
        removeAcceptChatListener()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configure() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidChanged(notifivation:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.addObsorverToUserAvatarInChatsNeedUpdate(observer: self,
                                                                    selector: #selector(updateAvatarInFriendsChats(notification:)))
        NotificationCenter.addObsorverRequestCountIsChange(observer: self,
                                                           selector: #selector(requestCountIsChange(notification:)))
    }
    
    //MARK: reloadData
    func reloadData(changeType: MTypeOfListenerChanges, chat: MChat, messageIsChanged: Bool?) {
        //for change tabbar badge
        
        
        switch changeType {
        case .add:
            acceptChatCollectionViewDelegate?.reloadDataSource(changeType: changeType)
        case .delete:
            acceptChatCollectionViewDelegate?.reloadDataSource(changeType: changeType)
        case .update:
            acceptChatCollectionViewDelegate?.reloadDataSource(changeType: changeType)
            
            //if selected chat update, send to messageCollectionView this chat
            if chat.friendId == lastSelectedChat?.friendId {
                messageCollectionViewDelegate?.chatsCollectionWasUpdate(chat: chat)
            }
            
            var isLastSeenMessage: Bool  {
                //last send date is not equel lastSeenMessage
                if chat.date != lastMessageInSelectedChat?.sentDate {
                    return false
                //last message sender is not equel sender current chat
                } else if lastMessageInSelectedChat?.sender.senderId != chat.lastMessageSenderID {
                    return false
                } else {
                    return true
                }
            }
            
            //show popUp notification if message is changed
            if messageIsChanged == true {
                //changedMessage not last seen massage in closed chat
                if !isLastSeenMessage {
                    PopUpService.shared.showMessagePopUp(header: chat.friendUserName,
                                                         text: chat.lastMessage,
                                                         time: chat.date.getFormattedDate(format: "HH:mm"),
                                                         imageStringURL: chat.friendUserImageString)
                    
                }
            }
        }
    }
}

extension AcceptChatDataProvider {
    
    //MARK: sceneDidChanged
    @objc private func sceneDidChanged(notifivation: Notification) {
        switch notifivation.name {
        case UIApplication.didEnterBackgroundNotification:
            BackgroundTaskManager.shared.submitBackgoundTaskShort()
        default:
            break
        }
    }
    
    @objc private func requestCountIsChange(notification: Notification) {
        guard
            let data = notification.userInfo as? [String: Int],
            let requestCount = data["requestCount"],
            let index = acceptChats.firstIndex(where: {$0.friendId == requestChatsCountName })
        else { return }
        
        acceptChats[index].lastMessage = String(requestCount)
        acceptChats[index].date = Date()
        acceptChatCollectionViewDelegate?.reloadDataSource(changeType: .update)
        
    }
    
    @objc private func updateAvatarInFriendsChats(notification: Notification) {
        guard let data = notification.userInfo as? [String: String],
              let imageString = data[MChat.CodingKeys.friendUserImageString.rawValue] else { return }
        FirestoreService.shared.updateAvatarInChats(currentUserID: userID,
                                                    avatarLink: imageString,
                                                    acceptChatsDelegate: self,
                                                    likeDelegate: nil)
    }
    
    //MARK: chatWasOpenClose
    private func chatWasOpenClose(isWasOpen: Bool, lastMessage: MMessage?, chat: MChat?) {
        guard let chat = chat else { return }
        FirestoreService.shared.currentUserOpenCloseChat(currentUserID: userID,
                                                         chat: chat,
                                                         isOpen: isWasOpen,
                                                         lastMessage: lastMessage) { result in
            switch result {
            
            case .success():
                break
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension AcceptChatDataProvider {
    func setupAcceptChatListener() {
        ListenerService.shared.addAcceptChatsListener(acceptChatDelegate: self)
    }
    
    func removeAcceptChatListener() {
        ListenerService.shared.removeAcceptChatsListener()
    }
}

//MARK:  getAcceptChats
extension AcceptChatDataProvider {
    
    func calculateUnreadAndNewChats() -> Int {
        let newChatsCount = acceptChats.filter { $0.isNewChat }.count - staticCellCount
        var unreadMessageCount = 0
        acceptChats.forEach { unreadMessageCount += $0.unreadChatMessageCount }
        let eventCount = unreadMessageCount + newChatsCount
        return eventCount
    }
    
     func getAcceptChats(complition: @escaping (Result<[MChat], Error>) -> Void) {
        
        //first get list of like people
        FirestoreService.shared.getUserCollection(userID: userID,
                                                  collection: MFirestorCollection.acceptChats) {[weak self] result in
            
            switch result {
            
            case .success(let chats):
                self?.acceptChats.append(contentsOf: chats)
                self?.checkInactiveChat()
                
                //try get and save to realm
                self?.getAcceptChatsToRealm { (result) in
                    switch result {
                    
                    case .success(_):
                        complition(.success(chats))
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                }
                
               
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
    
    //MARK: getAcceptChatsToRealm
    func getAcceptChatsToRealm(complition: @escaping (Result<[MChatRealm], Error>) -> Void) {
       
        //first get list of like people
        FirestoreService.shared.getChatsToRealmModel(
            userID: userID,
            collection: MFirestorCollection.acceptChats) { result in
            switch result {
            
            case .success(let realmChats):
                ManageRealmObjectService.shared.addChatToRealm(chats: realmChats,
                                                               complition: complition)
            case .failure(let error):
                complition(.failure(error))
            }
        }
        
    }
    
}


extension AcceptChatDataProvider {
    
    //MARK: checkInactiveChat
    //check chat for timeOfLife
    private func checkInactiveChat() {
        let strongUserID = userID

        let periodMinutesOfLifeChat = MChat.getDefaultPeriodMinutesOfLifeChat()
        let checkInterval = TimeInterval(1)
        Timer.scheduledTimer(withTimeInterval: checkInterval,
                             repeats: true) {[weak self] timer in
            timer.tolerance = 0.5
            self?.acceptChats.forEach { acceptChat in
                //if timer doesn't stop, than check period
                if !acceptChat.timerOfLifeIsStoped {
                    if acceptChat.createChatDate.checkPeriodIsPassed(periodMinuteCount: periodMinutesOfLifeChat) {
                        FirestoreService.shared.deleteChat(currentUserID: strongUserID, friendID: acceptChat.friendId)
                        //remove from collection
                        self?.acceptChats.removeAll(where: { chat -> Bool in
                            chat.friendId == acceptChat.friendId
                        })
                        //reload chats
                        self?.acceptChatCollectionViewDelegate?.reloadDataSource(changeType: .delete)
                    }
                }
            }
        }
    }
    
    //MARK: createRequestCountChat
    private func createRequestCountChat() {
        guard let dateForFirstCell = Date().getDateYearAgo(years: 100) else { fatalError("dateForFirstCell init fail")}
        
        let requestCountChat = MChat(friendUserName: requestChatsCountName,
                                     friendUserImageString: "",
                                     lastMessage: "0",
                                     lastMessageSenderID: "",
                                     isNewChat: true,
                                     friendId: requestChatsCountName,
                                     unreadChatMessageCount: 0,
                                     friendIsWantStopTimer: false,
                                     currentUserIsWantStopTimer: false,
                                     timerOfLifeIsStoped: true,
                                     createChatDate: dateForFirstCell,
                                     fcmKey: "",
                                     friendInChat: false,
                                     friendSawAllMessageInChat: true,
                                     date: Date())
        
        acceptChats.append(requestCountChat)
    }
}
