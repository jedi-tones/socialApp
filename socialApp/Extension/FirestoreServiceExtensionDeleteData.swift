//
//  FirestoreServiceProfileExtension.swift
//  socialApp
//
//  Created by Денис Щиголев on 19.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

//MARK: - WORK WITH PROFILE
extension FirestoreService {
    
    //MARK: deleteAllChats
    func deleteAllChats(forPeopleID: String, complition: @escaping ()-> Void) {
        
        //delete acceptChats
        let refChats = Firestore.firestore().collection([MFirestorCollection.users.rawValue, forPeopleID, MFirestorCollection.acceptChats.rawValue].joined(separator: "/"))
        
        //get all acceptChats, for delete messages collection
        getAlldocument(type: MChat.self, collection: refChats) {[weak self] chats in
            chats.forEach { chat in
                
                //delete all message in current chat
                let refMessages = refChats.document(chat.friendId).collection(MFirestorCollection.messages.rawValue)
                self?.deleteCollection(collection: refMessages)
                
                //friend chat
                guard let refFriendChat = self?.db.collection([MFirestorCollection.users.rawValue, chat.friendId, MFirestorCollection.acceptChats.rawValue].joined(separator: "/")) else { return }
                
                //delete all messages in friend chat
                let refFriendChatMessages = refFriendChat.document(forPeopleID).collection(MFirestorCollection.messages.rawValue)
                self?.deleteCollection(collection: refFriendChatMessages)
                
                //delete chat document from friend
                refFriendChat.document(forPeopleID).delete()
                
                //delete chat document from current user
                refChats.document(chat.friendId).delete()
                
                //delete chat images for this chat
                StorageService.shared.deleteChatImages(currentUserID: forPeopleID, friendUserID: chat.friendId)
            }
            complition()
        }
    }
    
    //MARK: deleteChat
    func deleteChat(currentUserID: String, friendID: String) {
        
        //delete acceptChats
        let refChat = db.document([MFirestorCollection.users.rawValue,
                                   currentUserID,
                                   MFirestorCollection.acceptChats.rawValue,
                                   friendID].joined(separator: "/"))
        let friendChat = db.document([MFirestorCollection.users.rawValue,
                                      friendID,
                                      MFirestorCollection.acceptChats.rawValue,
                                      currentUserID].joined(separator: "/"))
        
        let refMessageCollection = refChat.collection(MFirestorCollection.messages.rawValue)
        let refFriendMessageCollection = friendChat.collection(MFirestorCollection.messages.rawValue)
        //delete all messages from current and friend user
        deleteCollection(collection: refMessageCollection)
        deleteCollection(collection: refFriendMessageCollection)
        
        //delete chat document from current and friend user
        refChat.delete()
        friendChat.delete()
        
        //delete chat images
        StorageService.shared.deleteChatImages(currentUserID: currentUserID, friendUserID: friendID)
    }
    
    //MARK: delte input request
    func deleteInputRequest(currentUserID: String, complition: @escaping ()-> Void) {
        let refCurrentRequestChat = db.collection([MFirestorCollection.users.rawValue,
                                                   currentUserID,
                                                   MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
        
        getAlldocument(type: MChat.self, collection: refCurrentRequestChat) {[weak self] requestChats in
            requestChats.forEach { chat in
                //delete request chat for current user
                refCurrentRequestChat.document(chat.friendId).delete()
                //delete like chat for friend collection
                let refFriendLike = self?.db.collection([MFirestorCollection.users.rawValue,
                                                         chat.friendId,
                                                         MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
                
                refFriendLike?.document(currentUserID).delete()
            }
            complition()
        }
    }
    
    //MARK: delte output like
    func deleteOutputLike(currentUserID: String, complition: @escaping ()-> Void) {
        let refCurrentLikeChat = db.collection([MFirestorCollection.users.rawValue,
                                                currentUserID,
                                                MFirestorCollection.likePeople.rawValue].joined(separator: "/"))
        
        getAlldocument(type: MChat.self, collection: refCurrentLikeChat) {[weak self] likeChats in
            likeChats.forEach { chat in
                //delete output like chat for current user
                refCurrentLikeChat.document(chat.friendId).delete()
                //delete request chat for friend collection
                let refFriendRequest = self?.db.collection([MFirestorCollection.users.rawValue,
                                                            chat.friendId,
                                                            MFirestorCollection.requestsChats.rawValue].joined(separator: "/"))
                
                refFriendRequest?.document(currentUserID).delete()
            }
            complition()
        }
    }
    
    //MARK: delete all dislike
    func deleteAllDislikes(userID: String, complition: @escaping ()-> Void) {
        
        let refCurrentRequestChat = db.collection([MFirestorCollection.users.rawValue,
                                                   userID,
                                                   MFirestorCollection.dislikePeople.rawValue].joined(separator: "/"))
        getAlldocument(type: MChat.self, collection: refCurrentRequestChat) { dislikeChats in
            dislikeChats.forEach { dislikeChat in
                refCurrentRequestChat.document(dislikeChat.friendId).delete()
            }
            complition()
        }
    }
    
    //MARK: delete profile document
    func deleteProfileDocument(userID: String, complition: @escaping ()-> Void) {
        let refCurrentUser = db.collection(MFirestorCollection.users.rawValue).document(userID)
        refCurrentUser.delete()
        //delete profile images
        StorageService.shared.deleteProfileImages(userID: userID)
        complition()
    }
    
    
    //MARK: unMatch
    func unMatch(currentUserID: String, chat: MChat, complition:@escaping(Result<MDislike,Error>)->Void) {
        //delete all chat and messages
        deleteChat(currentUserID: currentUserID, friendID: chat.friendId)
        //add dislike to current and friend collection
        let refCurrentDislike = db.collection([MFirestorCollection.users.rawValue, currentUserID, MFirestorCollection.dislikePeople.rawValue].joined(separator: "/"))
        let refFriendDislike = db.collection([MFirestorCollection.users.rawValue, chat.friendId, MFirestorCollection.dislikePeople.rawValue].joined(separator: "/"))
        
        var dislikeChat = MDislike(dislikePeopleID: chat.friendId, date: Date())
        
        do {
            try refCurrentDislike.document(chat.friendId).setData(from: dislikeChat)
            //change info in chat and write to friend dislike collection
            dislikeChat.dislikePeopleID = currentUserID
            try refFriendDislike.document(currentUserID).setData(from: dislikeChat)
            //unsubscribe from push notificasion
            PushMessagingService.shared.unSubscribeToChatNotification(currentUserID: currentUserID,
                                                                      chatUserID: dislikeChat.dislikePeopleID)
         
            complition(.success(dislikeChat))
        } catch { complition(.failure(error))}
    }
    
    //MARK: delete all profile data
    func deleteAllProfileData(userID: String, complition: @escaping () -> Void) {
        deleteAllChats(forPeopleID: userID) { [weak self] in
            //delete input requests and like chats for people who send a request
            self?.deleteInputRequest(currentUserID: userID, complition: {
                //delete output likes and request who got a like
                self?.deleteOutputLike(currentUserID: userID, complition: {
                    //delete all dislikes users
                    self?.deleteAllDislikes(userID: userID, complition: {
                        //delete profile document
                        self?.deleteProfileDocument(userID: userID, complition: {
                            //delete current user Auth data
                            AuthService.shared.deleteUser { result in
                                switch result {
                                
                                case .success(let isDelete):
                                    if isDelete {
                                        complition()
                                    }
                                case .failure(let error):
                                    fatalError(error.localizedDescription)
                                }
                            }
                        })
                    })
                })
            })
        }
    }
}
