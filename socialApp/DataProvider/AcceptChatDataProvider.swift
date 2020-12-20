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
    var acceptChats: [MChat] = []
    var sortedAcceptChats: [MChat] {
        let accept = acceptChats.sorted {
            $0.date > $1.date
        }
        return accept
    }
    private var lastSelectedChat: MChat?
    var lastMessageInSelectedChat: MMessage? {
        didSet {
            BackgroundTaskManager.shared.setCurrentOpenMessage(acceptChatDelegate: self,
                                                               currentUserID: userID,
                                                               openChat: lastSelectedChat,
                                                               lastMessage: lastMessageInSelectedChat)
        }
    }
     
    weak var acceptChatCollectionViewDelegate: AcceptChatCollectionViewDelegate?
    weak var messageCollectionViewDelegate: MessageControllerDelegate? {
        didSet {
            print("didset")
            if let selectedMessageCollectionView = messageCollectionViewDelegate {
                lastSelectedChat = selectedMessageCollectionView.chat
                chatWasOpenClose(isWasOpen: true,
                                 lastMessage: selectedMessageCollectionView.lastMessage,
                                 chat: lastSelectedChat)
            } else {
                chatWasOpenClose(isWasOpen: false,
                                 lastMessage: lastMessageInSelectedChat,
                                 chat: lastSelectedChat)
                lastSelectedChat = nil
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
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidChanged(notifivation:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidChanged(notifivation:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    func reloadData(changeType: MTypeOfListenerChanges, chat: MChat, messageIsChanged: Bool?) {
        
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
            
            let isNotLatsSennMessage =
                chat.date != lastMessageInSelectedChat?.sentDate &&
                chat.friendId != lastMessageInSelectedChat?.sender.senderId
            let isLastSeenMessage: Bool =
                //last send date equel lastSeenMessage
                (chat.date == lastMessageInSelectedChat?.sentDate)
                //and last sender or current user or admin
                && ((lastMessageInSelectedChat?.sender.senderId == chat.friendId)
                        || (lastMessageInSelectedChat?.sender.senderId == userID)
                        || (lastMessageInSelectedChat?.sender.senderId == MAdmin.id.rawValue))
            
            //show popUp notification if message is changed
            if messageIsChanged == true {
                //changedMessage not last seen massage in closed chat
                if !isLastSeenMessage {
                    //and this chat don't open
                    if chat.friendId != lastSelectedChat?.friendId || lastSelectedChat == nil {
                        PopUpService.shared.showMessagePopUp(header: chat.friendUserName,
                                                             text: chat.lastMessage,
                                                             time: chat.date.getFormattedDate(format: "HH:mm"),
                                                             imageStringURL: chat.friendUserImageString)
                    }
                }
            }
        }
    }
}

extension AcceptChatDataProvider {
    
    @objc private func sceneDidChanged(notifivation: Notification) {
        switch notifivation.name {
        case UIApplication.didEnterBackgroundNotification:
            BackgroundTaskManager.shared.submitBackgoundTaskShort()
        case UIApplication.willTerminateNotification:
            print("accept chats will terminate")
           // BackgroundTaskManager.shared.submitBackgroundTasks()
        default:
            break
        }
    }
    private func chatWasOpenClose(isWasOpen: Bool, lastMessage: MMessage?, chat: MChat?) {
        guard let chat = chat else { return }
        print("isWasOpen :\(isWasOpen)")
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
