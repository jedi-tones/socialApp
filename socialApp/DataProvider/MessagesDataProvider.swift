//
//  MessagesDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 30.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class MessagesDataProvider: MessageListenerDelegate {
    
    let userID: String
    var messages:[MMessage] = [] {
        didSet {
            messageControllerDelegate?.lastMessage = messages.last
        }
    }
    weak var messageControllerDelegate: MessageControllerDelegate?
    
    init(userID: String) {
        self.userID = userID
    }
}

extension MessagesDataProvider {
    
    func getAllMessages(currentUserId: String, chat: MChat, complition: @escaping (Result<[MMessage], Error>) -> Void) {
        FirestoreService.shared.getAllMessagesInChat(currentUserID: currentUserId,
                                                     chat: chat) {[unowned self] result in
            switch result {
            
            case .success(let newMessages):
                self.messages = newMessages
                self.messages.sort { lhs, rhs -> Bool in
                    lhs.sentDate < rhs.sentDate
                }
                complition(.success(newMessages))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
    
    func setupListener(chat: MChat) {
        
        ListenerService.shared.messageListener(chat: chat) {[weak self] result in
            switch result {
            
            case .success(let message):
                guard let messages = self?.messages else { return }
                guard !messages.contains(message) else { return }
                self?.messages.append(message)
                self?.messages.sort { lhs, rhs -> Bool in
                    lhs.sentDate < rhs.sentDate
                }
                self?.messageControllerDelegate?.newMessage()
                
            case .failure(let error):
                guard let isInitiateDeleteChat = self?.messageControllerDelegate?.isInitiateDeleteChat else { return }
                //if user don't press delete chat, show alert and close chat
                if !isInitiateDeleteChat {
                    self?.messageControllerDelegate?.showChatAlert(text: error.localizedDescription)
                }
            }
        }
    }
    
    func removeListener() {
        messages = []
        ListenerService.shared.removeMessageListener()
    }
}
