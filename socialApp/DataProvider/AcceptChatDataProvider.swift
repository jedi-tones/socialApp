//
//  AcceptChatDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 29.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class AcceptChatDataProvider: AcceptChatListenerDelegate {
    
    var userID: String
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
               // lastSelectedChat = nil
            }
        }
    }
    
    init(userID: String) {
        self.userID = userID
        configure()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configure() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidChanged(notifivation:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.addObsorverToUserAvatarInChatsNeedUpdate(observer: self,
                                                                    selector: #selector(updateAvatarInFriendsChats(notification:)))
    }
    
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
                    //and this chat don't open
                    
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
        let newChatsCount = acceptChats.filter { $0.isNewChat }.count
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
            
            case .success(let acceptChats):
                self?.acceptChats = acceptChats
                self?.checkInactiveChat()
                complition(.success(acceptChats))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
}

//MARK: checkInactiveChat
extension AcceptChatDataProvider {
    //check chat for timeOfLife
    func checkInactiveChat() {
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
}
