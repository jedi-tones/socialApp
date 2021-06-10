//
//  FirestoreServiceExtensionChatAction.swift
//  socialApp
//
//  Created by Денис Щиголев on 19.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import FirebaseFirestore

extension FirestoreService {
    //MARK: sendChatRequest
//    func sendChatRequest(fromUser: MPeople, forFrend: MPeople, text:String?, complition: @escaping(Result<MMessage,Error>)->Void) {
//
//        let textToSend = text ?? MLabels.requestMessage.rawValue
//        let collectionRequestRef = db.collection([MFirestorCollection.users.rawValue, forFrend.senderId, MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
//        let messagesRef = collectionRequestRef.document(fromUser.senderId).collection(MFirestorCollection.messages.rawValue)
//        let messageRef = messagesRef.document(MFirestorCollection.requestMessage.rawValue)
//        let lastMessageSender = textToSend == "" ? "" : fromUser.senderId
//        let sender = MSender(senderId: fromUser.senderId, displayName: fromUser.displayName)
//        let message = MMessage(user: sender, content: textToSend, id: messagesRef.path)
//        let chatMessage = MChat(friendUserName: fromUser.displayName,
//                                friendUserImageString: fromUser.userImage,
//                                lastMessage: textToSend,
//                                lastMessageSenderID: lastMessageSender,
//                                isNewChat: false,
//                                friendId: fromUser.senderId,
//                                unreadChatMessageCount: 0,
//                                friendIsWantStopTimer: false,
//                                currentUserIsWantStopTimer: false,
//                                timerOfLifeIsStoped: false,
//                                createChatDate: Date(),
//                                fcmKey: fromUser.fcmKey,
//                                friendInChat: false,
//                                friendSawAllMessageInChat: <#T##Bool#>
//                                date: Date())
//
//        do { //add chat request document for reciever user
//            try collectionRequestRef.document(fromUser.senderId).setData(from: chatMessage, merge: true)
//            //add message to collection messages in ChatRequest
//            messageRef.setData(message.reprasentation)
//            complition(.success(message))
//        } catch { complition(.failure(error)) }
//    }
    
    //MARK: deleteChatRequest
    func deleteChatRequest(fromUser: MChat, forUser: MPeople) {
        
        let collectionRequestRef = db.collection([MFirestorCollection.users.rawValue, forUser.senderId, MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        let messagesRef = collectionRequestRef.document(fromUser.friendId).collection(MFirestorCollection.messages.rawValue)
        
        //delete all document in message collection for delete this collection
        deleteCollection(collection: messagesRef)
        //and delete request from userID document
        collectionRequestRef.document(fromUser.friendId).delete()
    }
    
    //MARK: likePeople
    func likePeople(currentPeople: MPeople, likePeople: MPeople,message: String = "", requestChats: [MChat], complition: @escaping(_ result: Result<MChat,Error>, _ isMatch: Bool)->Void) {
        
        let collectionLikeUserRequestRef = db.collection([MFirestorCollection.users.rawValue, likePeople.senderId, MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        let collectionLikeUserAcceptChatRef = db.collection([MFirestorCollection.users.rawValue, likePeople.senderId, MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
        let collectionLikeUserLikeRef = db.collection([MFirestorCollection.users.rawValue, likePeople.senderId, MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
        let collectionCurrentRequestRef = db.collection([MFirestorCollection.users.rawValue, currentPeople.senderId, MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        let collectionCurrentLikeRef = db.collection([MFirestorCollection.users.rawValue, currentPeople.senderId, MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
        let collectionCurrentAcceptChatRef = db.collection([MFirestorCollection.users.rawValue, currentPeople.senderId, MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
        
        let likeUserMessagesRef = collectionLikeUserAcceptChatRef.document(currentPeople.senderId).collection(MFirestorCollection.messages.rawValue)
        let likeUserMessageRef = likeUserMessagesRef.document(MFirestorCollection.requestMessage.rawValue)
        let currentUserMessagesRef = collectionCurrentAcceptChatRef.document(currentPeople.senderId).collection(MFirestorCollection.messages.rawValue)
        let currentUserMessageRef = currentUserMessagesRef.document(MFirestorCollection.requestMessage.rawValue)
        
        var requestChat = MChat(friendUserName: currentPeople.displayName,
                                friendUserImageString: currentPeople.userImage,
                                lastMessage: message,
                                lastMessageSenderID: "",
                                isNewChat: true,
                                friendId: currentPeople.senderId,
                                unreadChatMessageCount: 0,
                                friendIsWantStopTimer: false,
                                currentUserIsWantStopTimer: false,
                                timerOfLifeIsStoped: false,
                                createChatDate: Date(),
                                fcmKey: currentPeople.fcmKey,
                                friendInChat: false,
                                friendSawAllMessageInChat: true,
                                date: Date())
        var likeChat = MChat(friendUserName: likePeople.displayName,
                             friendUserImageString: likePeople.userImage,
                             lastMessage: message,
                             lastMessageSenderID: "",
                             isNewChat: true,
                             friendId: likePeople.senderId,
                             unreadChatMessageCount: 0,
                             friendIsWantStopTimer: false,
                             currentUserIsWantStopTimer: false,
                             timerOfLifeIsStoped: false,
                             createChatDate: Date(),
                             fcmKey: likePeople.fcmKey,
                             friendInChat: false,
                             friendSawAllMessageInChat: true,
                             date: Date())
        
        //if like people contains in current user request chat than add to newChat and delete in request
        let requestChatFromLikeUser = requestChats.filter { requestChat -> Bool in
            requestChat.containsID(ID: likePeople.senderId)
        }
        //if have requst chat from like user
        if let chat = requestChatFromLikeUser.first {
            //delete from request
            collectionCurrentRequestRef.document(likePeople.senderId).delete()
            //delete from like in like user collection
            collectionLikeUserLikeRef.document(currentPeople.senderId).delete()
            let sender = MSender(senderId: currentPeople.senderId, displayName: currentPeople.displayName)
            var requestMessage = MMessage(user: sender,
                                          content: chat.lastMessage,
                                          id: currentUserMessageRef.path)
            
            //add to acceptChat to current user
            do {
                //if with first message, create chat and message in collection
                if !chat.lastMessage.isEmpty {
                    likeChat.unreadChatMessageCount = 1
                    likeChat.lastMessageSenderID = likePeople.senderId
                    try collectionCurrentAcceptChatRef.document(likePeople.senderId).setData(from: likeChat)
                    currentUserMessageRef.setData(requestMessage.reprasentation)
                } else {
                    try collectionCurrentAcceptChatRef.document(likePeople.senderId).setData(from: likeChat)
                }
            } catch { complition(.failure(error), false)}
            
            //add to acceptChat to like user
            do {
                if !chat.lastMessage.isEmpty {
                    //set that friend don't see last message
                    requestChat.friendSawAllMessageInChat = false
                    try collectionLikeUserAcceptChatRef.document(currentPeople.senderId).setData(from: requestChat)
                    //change message id to likeUser path
                    requestMessage.messageId = likeUserMessageRef.path
                    //if with first message, create message in collection
                    likeUserMessageRef.setData(requestMessage.reprasentation)
                    
                    PushMessagingService.shared.sendPushMessageToToken(token: likePeople.fcmKey,
                                                                       header: "У тебя новая пара с \(currentPeople.displayName)",
                                                                       text: "Начни общение, чат удалится через сутки",
                                                                       category: MActionType.request)
                    complition(.success(likeChat), true)
                } else {
                    try collectionLikeUserAcceptChatRef.document(currentPeople.senderId).setData(from: requestChat)
                    PushMessagingService.shared.sendPushMessageToToken(token: likePeople.fcmKey,
                                                                       header: "У тебя новая пара с \(currentPeople.displayName)",
                                                                       text: "Начни общение, чат удалится через сутки",
                                                                       category: MActionType.request)
                    complition(.success(likeChat), true)
                }
            } catch { complition(.failure(error), false)}
            
            //if don't have request from like user
        } else {
            do { //add chat request for like user
                try collectionLikeUserRequestRef.document(currentPeople.senderId).setData(from: requestChat, merge: true)
                //add chat to like collection current user
                try collectionCurrentLikeRef.document(likePeople.senderId).setData(from:likeChat)
                
                PushMessagingService.shared.sendPushMessageToToken(token: likePeople.fcmKey,
                                                                   header: "У тебя новый лайк",
                                                                   text: "Скорее заходи, возможно это взаимно",
                                                                   category: MActionType.request)
        
                complition(.success(likeChat), false)
            } catch { complition(.failure(error), false) }
        }
    }
    
    
    //MARK: dislikePeople
    func dislikePeople(currentPeople: MPeople,
                       dislikeForPeopleID: String,
                       requestChats: [MChat],
                       viewControllerDelegate: UIViewController,
                       complition: @escaping(Result<(MDislike,Bool),Error>)->Void) {
        let collectionCurrentUserDislikeRef = usersReference.document(currentPeople.senderId).collection(MFirestorCollection.dislikePeople.rawValue)
        let collectionCurrentRequestRef = db.collection([MFirestorCollection.users.rawValue, currentPeople.senderId, MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        let collectionDislikeUserLikeRef = db.collection([MFirestorCollection.users.rawValue, dislikeForPeopleID, MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
        
        let dislikeChat = MDislike(dislikePeopleID: dislikeForPeopleID, date: Date())
        var isMissMatch = false
        
        //unsubscribe from push notificasion
        PushMessagingService.shared.unSubscribeToChatNotification(currentUserID: currentPeople.senderId,
                                                                  chatUserID: dislikeChat.dislikePeopleID)
        
        //if dislike people contains in current user request chat
        let requestChatFromLikeUser = requestChats.filter { requestChat -> Bool in
            requestChat.containsID(ID: dislikeForPeopleID)
        }
        //if have requst chat from dislike user
        if let _ = requestChatFromLikeUser.first {
            
            //delete from request
            collectionCurrentRequestRef.document(dislikeForPeopleID).delete()
            //delete from like in dislike user collection
            collectionDislikeUserLikeRef.document(currentPeople.senderId).delete()
            isMissMatch = true
            
        }
        do {
            try collectionCurrentUserDislikeRef.document(dislikeForPeopleID).setData(from: dislikeChat)
            
            complition(.success((dislikeChat,isMissMatch)))
        } catch { complition(.failure(error))}
    }
    
    //MARK: addReport
    func addReport(currentUserID: String,
                   reportUserID: String,
                   typeOfReport: String,
                   text: String,
                   inChat: Bool,
                   complition:@escaping(Result<MReports,Error>)->Void) {
        
        let collectionCurrentUserReportRef = usersReference.document(currentUserID).collection(MFirestorCollection.reportUser.rawValue)
        let collectionCurrentRequestRef = db.collection([MFirestorCollection.users.rawValue, currentUserID, MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        
        let collectionReportUserLikeRef = db.collection([MFirestorCollection.users.rawValue, reportUserID, MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
        let collectionReportUserReportRef = db.collection([MFirestorCollection.users.rawValue, reportUserID, MFirestorCollection.reportUser.rawValue].joined(separator: "/"))
        let reportUserRef = usersReference.document(reportUserID)
        
        //for save to current user collection
        let report = MReports(reportUserID: reportUserID,
                              typeOfReports: MTypeReports.init(rawValue: typeOfReport) ?? MTypeReports.other,
                              text: text)
        //report for add to report user collection
        let reportForReportUser = MReports(reportUserID: currentUserID,
                                           typeOfReports: MTypeReports.other,
                                           text: MTypeReports.getReport)
        //for add report to user profile
        let reportDiscription: [String : Any] = [MReports.CodingKeys.reportUserID.rawValue : currentUserID,
                                                 MReports.CodingKeys.typeOfReports.rawValue : typeOfReport,
                                                 MReports.CodingKeys.text.rawValue : text]
        
        reportUserRef.setData([MPeople.CodingKeys.reportList.rawValue : FieldValue.arrayUnion([reportDiscription])],
                              merge: true) {[weak self] error in
            if let error = error {
                complition(.failure(error))
            } else {
                //delete chat
                if inChat {
                    self?.deleteChat(currentUserID: currentUserID, friendID: reportUserID)
                }
                //unsubscribe from push notificasion
                PushMessagingService.shared.unSubscribeToChatNotification(currentUserID: currentUserID,
                                                                          chatUserID: reportUserID)
                
                //delete from chatRequest
                collectionCurrentRequestRef.document(reportUserID).delete()
                //delete from like in report user collection
                collectionReportUserLikeRef.document(currentUserID).delete()
                
                //add to report collection
                do {
                    try collectionCurrentUserReportRef.document(reportUserID).setData(from: report)
                    try collectionReportUserReportRef.document(currentUserID).setData(from: reportForReportUser)
                    complition(.success(report))
                } catch { complition(.failure(error))}
            }
        }
    }
    
    //MARK: currentUserOpenCloseChat
    func currentUserOpenCloseChat(currentUserID: String,
                                  chat: MChat,
                                  isOpen: Bool,
                                  lastMessage: MMessage?,
                                  complition: @escaping(Result<(),Error>) -> Void) {
        
        let refChat = db.document([MFirestorCollection.users.rawValue,
                                   currentUserID,
                                   MFirestorCollection.acceptChats.rawValue,
                                   chat.friendId].joined(separator: "/"))
        
        let refFriendChat = db.document([MFirestorCollection.users.rawValue,
                                         chat.friendId,
                                         MFirestorCollection.acceptChats.rawValue,
                                         currentUserID].joined(separator: "/"))
        
        let batch = db.batch()
        //if chat was open, read all message in currentUser chat
        if isOpen {
            batch.setData([MChat.CodingKeys.unreadChatMessageCount.rawValue : 0],
                          forDocument: refChat,
                          merge: true)
            
        } else if let lastMessage = lastMessage {
            //if chat was close and have last message, set last message and new date in currentUser chat
            var lastMessageText = ""
            //if text content
            if let textContent = lastMessage.content {
                lastMessageText = textContent
                //if image content
            } else if let _ = lastMessage.imageURL {
                lastMessageText = "Фото 📷"
            }
            
            batch.setData([MChat.CodingKeys.lastMessage.rawValue : lastMessageText,
                           MChat.CodingKeys.lastMessageSenderID.rawValue: lastMessage.sender.senderId,
                           MChat.CodingKeys.date.rawValue : lastMessage.sentDate],
                          forDocument: refChat,
                          merge: true)
        }
        //change state friendInChat in friend chat, and set that current user see all message
        batch.setData([MChat.CodingKeys.friendInChat.rawValue : isOpen,
                       MChat.CodingKeys.friendSawAllMessageInChat.rawValue : true],
                      forDocument: refFriendChat,
                      merge: true)
        
        batch.commit { error in
            if let error = error {
                complition(.failure(error))
            } else {
                complition(.success(()))
            }
        }
    }
    
    //MARK: deactivateChatTimer
    func deactivateChatTimer(currentUser: MPeople, chat: MChat, complition: @escaping (Result<(),Error>)-> Void) {
        let refCurrentChatCollection = db.collection([MFirestorCollection.users.rawValue,
                                                      currentUser.senderId,
                                                      MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
        let refFriendChatCollection = db.collection([MFirestorCollection.users.rawValue,
                                                     chat.friendId,
                                                     MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
        let currentChatDocument = refCurrentChatCollection.document(chat.friendId)
        let friendChatDocument = refFriendChatCollection.document(currentUser.senderId)
        
        if chat.friendIsWantStopTimer || currentUser.isGoldMember || currentUser.isTestUser {
            //if friend already want to stop chat timer, set timer is stoped to friend chat
            friendChatDocument.updateData([MChat.CodingKeys.friendIsWantStopTimer.rawValue : true,
                                           MChat.CodingKeys.timerOfLifeIsStoped.rawValue: true,
                                           MChat.CodingKeys.currentUserIsWantStopTimer.rawValue : true]) { error in
                if let error = error  {
                    complition(.failure(error))
                } else {
                    //set timer is stoped to current chat
                    currentChatDocument.updateData([MChat.CodingKeys.friendIsWantStopTimer.rawValue : true,
                                                    MChat.CodingKeys.timerOfLifeIsStoped.rawValue: true,
                                                    MChat.CodingKeys.currentUserIsWantStopTimer.rawValue: true]) { error in
                        if let error = error  {
                            complition(.failure(error))
                        } else {
                            //send admin message about the chat timer is stop
                            var messageText = ""
                            if currentUser.isGoldMember || currentUser.isTestUser {
                                messageText = "\(currentUser.displayName)\(MLabels.chatTimerIsStopWithPremium.rawValue)"
                            } else {
                                messageText = MLabels.chatTimerIsStop.rawValue
                            }
                            FirestoreService.shared.sendAdminMessage(currentUser: currentUser,
                                                                     chat: chat,
                                                                     text: messageText) { _ in
                                //send notification to friend
                                PushMessagingService.shared.sendPushMessageToToken(token: chat.fcmKey,
                                                                                   header: MAdmin.displayName.rawValue,
                                                                                   text: messageText,
                                                                                   category: .systemMessage)
                        
                            }
                            complition(.success(()))
                        }
                    }
                }
            }
            
        } else {
            //if friend doesn't want stop timer, set to friend's chat, that you want to stop timer
            friendChatDocument.updateData([MChat.CodingKeys.friendIsWantStopTimer.rawValue : true]) { error in
                if let error = error {
                    complition(.failure(error))
                } else {
                    //set current user want stop timer
                    currentChatDocument.updateData([MChat.CodingKeys.currentUserIsWantStopTimer.rawValue: true]) { error in
                        guard error == nil else {
                            complition(.failure(error!))
                            return
                        }
                        let messageText = currentUser.displayName + MLabels.userStopChatTimer.rawValue
                        //send admin message about the current user send request to stop chat
                        FirestoreService.shared.sendAdminMessage(currentUser: currentUser,
                                                                 chat: chat,
                                                                 text: messageText) { _ in
                            
                            PushMessagingService.shared.sendPushMessageToToken(token: chat.fcmKey,
                                                                               header: MAdmin.displayName.rawValue,
                                                                               text: messageText,
                                                                               category: .systemMessage)
                            
                        }
                        complition(.success(()))
                    }
                }
            }
        }
    }
    
    //MARK: sendMessage
    func sendMessage(chat: MChat,
                     currentUser: MPeople,
                     message: MMessage,
                     complition: @escaping(Result<Void, Error>)-> Void) {
        let refFriendChat = db.document([MFirestorCollection.users.rawValue,
                                         chat.friendId,
                                         MFirestorCollection.acceptChats.rawValue,
                                         currentUser.senderId].joined(separator: "/"))
        let refSenderChat = db.document([MFirestorCollection.users.rawValue,
                                         currentUser.senderId,
                                         MFirestorCollection.acceptChats.rawValue,
                                         chat.friendId].joined(separator: "/"))
        
        let refFriendMessage = refFriendChat.collection(MFirestorCollection.messages.rawValue)
        let refSenderMessage = refSenderChat.collection(MFirestorCollection.messages.rawValue)
        
        refFriendMessage.addDocument(data: message.reprasentation) {[unowned self] error in
            if let error = error {
                complition(.failure(error))
            } else {
                refSenderMessage.addDocument(data: message.reprasentation) { error in
                    if let error = error {
                        complition(.failure(error))
                    } else {
                        
                        //set lastMessageText
                        var lastMessageText = ""
                        if let messageContent = message.content {
                            lastMessageText = messageContent
                        } else if let _ = message.imageURL {
                            lastMessageText = "Фото 📷"
                        }
                        
                        let batch = db.batch()
                        //if friend don't open chat, set new last message to him, and increment unread message
                        if !chat.friendInChat {
                            batch.setData([MChat.CodingKeys.lastMessage.rawValue: lastMessageText,
                                           MChat.CodingKeys.lastMessageSenderID.rawValue: message.sender.senderId,
                                           MChat.CodingKeys.date.rawValue: message.sentDate,
                                           MChat.CodingKeys.isNewChat.rawValue: false,
                                           MChat.CodingKeys.unreadChatMessageCount.rawValue : FieldValue.increment(Int64(1))],
                                          forDocument: refFriendChat,
                                          merge: true)
                            
                            //and change status of unsee message in current user chat
                            if chat.friendSawAllMessageInChat || chat.isNewChat {
                                batch.setData([MChat.CodingKeys.friendSawAllMessageInChat.rawValue : false,
                                               MChat.CodingKeys.isNewChat.rawValue: false],
                                              forDocument: refSenderChat,
                                              merge: true)
                            }
                        }
                        
                        batch.commit { error in
                            if let error = error {
                                complition(.failure(error))
                            } else {
                                complition(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: sendAdminMessage
    func sendAdminMessage(currentUser:MPeople, chat: MChat, text: String, complition: @escaping(Result<(),Error>)-> Void) {
        let sender = MSender.getAdminSender()
        let message = MMessage(user: sender, content: text)
        
        FirestoreService.shared.sendMessage(chat: chat,
                                            currentUser: currentUser,
                                            message: message) { result in
            switch result {
            
            case .success():
                complition(.success(()))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
}
