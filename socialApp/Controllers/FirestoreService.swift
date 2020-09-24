//
//  FirestoreService.swift
//  socialApp
//
//  Created by Денис Щиголев on 07.09.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import FirebaseAuth

class FirestoreService {
    
    static let shared = FirestoreService()
    
    private init() {}
    
    private let db = Firestore.firestore()
    
    private var usersReference: CollectionReference {
        db.collection("users")
    }
    
    //MARK:  saveAvatar
    func saveAvatar(image: UIImage?, user: User, complition: @escaping (Result<String, Error>) -> Void) {
        
        guard let avatar = image else { fatalError("cant get userProfile image") }
        //if user choose photo, than upload new photo to Storage
        if  image != #imageLiteral(resourceName: "avatar")  {
            StorageService.shared.uploadImage(image: avatar) {[weak self] result in
                switch result {
                
                case .success(let url):
                    let userImageString = url.absoluteString
                    //save user to FireStore
                    self?.usersReference.document(user.uid).setData(["userImage" : userImageString], merge: true, completion: { error in
                        if let error = error {
                            complition(.failure(error))
                        } else {
                            complition(.success(userImageString))
                        }
                    })
                case .failure(_):
                    fatalError("Cant upload Image")
                }
            }
        }
    }
    
    //MARK:  saveBaseProfile
    func saveBaseProfile(id: String,
                         email: String,
                         complition: @escaping (Result<Void, Error>) -> Void){
        
        //save base user info to cloud FireStore
        usersReference.document(id).setData([MPeople.CodingKeys.id.rawValue : id,
                                             MPeople.CodingKeys.mail.rawValue: email,
                                             MPeople.CodingKeys.isActive.rawValue: false],
                                            merge: true,
                                            completion: { (error) in
                                                if let error = error {
                                                    fatalError(error.localizedDescription)
                                                } else {
                                                    complition(.success(()))
                                                }
                                            })
    }
    //MARK:  saveGender
    func saveGender(user: User, gender: String, complition: @escaping (Result<Void, Error>) -> Void) {
        usersReference.document(user.uid).setData([MPeople.CodingKeys.sex.rawValue : gender],
                                                  merge: true,
                                                  completion: { (error) in
                                                    if let error = error {
                                                        complition(.failure(error))
                                                    } else {
                                                        complition(.success(()))
                                                    }
                                                  })
    }
    
    //MARK:  saveWant
    func saveWant(user: User, want: String, complition: @escaping (Result<Void, Error>) -> Void) {
        usersReference.document(user.uid).setData([MPeople.CodingKeys.search.rawValue : want],
                                                  merge: true,
                                                  completion: { (error) in
                                                    if let error = error {
                                                        complition(.failure(error))
                                                    } else {
                                                        complition(.success(()))
                                                    }
                                                  })
    }
    
    //MARK:  saveDefaultImage
    func saveDefaultImage(user: User, defaultImageString: String, complition: @escaping (Result<Void, Error>) -> Void) {
        usersReference.document(user.uid).setData([MPeople.CodingKeys.userImage.rawValue : defaultImageString],
                                                  merge: true,
                                                  completion: { (error) in
                                                    if let error = error {
                                                        complition(.failure(error))
                                                    } else {
                                                        complition(.success(()))
                                                    }
                                                  })
    }
    
    //MARK: - saveAdvertAndName
    func saveAdvertAndName(user: User,
                           userName: String,
                           advert: String,
                           isActive: Bool,
                           complition: @escaping (Result<Void, Error>) -> Void){
        usersReference.document(user.uid).setData([MPeople.CodingKeys.userName.rawValue : userName,
                                                   MPeople.CodingKeys.advert.rawValue: advert,
                                                   MPeople.CodingKeys.isActive.rawValue: isActive],
                                                  merge: true,
                                                  completion: { (error) in
                                                    if let error = error {
                                                        complition(.failure(error))
                                                    } else {
                                                        complition(.success(()))                                                    }
                                                  })
    }
    
    //MARK:  getUserData
    func getUserData(userID: String, complition: @escaping (Result<MPeople,Error>) -> Void) {
        
        let documentReference = usersReference.document(userID)
        documentReference.getDocument { (snapshot, error) in
            
            if let snapshot = snapshot, snapshot.exists {
                
                guard let people = MPeople(documentSnap: snapshot) else {
                    complition(.failure(UserError.incorrectSetProfile))
                    return
                }
                complition(.success(people))
                
            } else {
                complition(.failure(UserError.notAvailableUser))
            }
        }
    }
    
    //MARK: sendChatRequest
    func sendChatRequest(fromUser: MPeople, forFrend: MPeople, text:String?, complition: @escaping(Result<MMessage,Error>)->Void) {
        
        let textToSend = text ?? ""
        let collectionRequestRef = db.collection(["users", forFrend.id, "chatRequest"].joined(separator: "/"))
        let messagesRef = collectionRequestRef.document(fromUser.id).collection("messages")
        let messageRef = messagesRef.document("requestMessage")
        
        let message = MMessage(user: fromUser, content: textToSend, id: messagesRef.path)
        let chatMessage = MChat(friendUserName: fromUser.userName,
                                friendUserImageString: fromUser.userImage,
                                lastMessage: message.content,
                                friendId: fromUser.id,
                                date: Date())
        
        do { //add chat request document for reciever user
            try collectionRequestRef.document(fromUser.id).setData(from: chatMessage, merge: true)
            do {//add message to collection messages in ChatRequest
                try messageRef.setData(from: message)
                complition(.success(message))
            } catch {  complition(.failure(error)) }
        } catch { complition(.failure(error)) }
    }
    
    //MARK: deleteChatRequest
    func deleteChatRequest(fromUser: MChat, forUser: User) {
        
        let collectionRequestRef = db.collection(["users", forUser.uid, "chatRequest"].joined(separator: "/"))
        let messagesRef = collectionRequestRef.document(fromUser.friendId).collection("messages")
        
        //delete all document in message collection for delete this collection
        deleteCollection(collection: messagesRef)
        //and delete request from userID document 
        collectionRequestRef.document(fromUser.friendId).delete()
    }
    
    //MARK: changeToActive
    func changeToActive(chat: MChat, forUser: User) {
        
        let collectionRequestRef = db.collection(["users", forUser.uid, "chatRequest"].joined(separator: "/"))
        let collectionActiveRef = db.collection(["users", forUser.uid, "chatActive"].joined(separator: "/"))
        let collectionFriendActiveRef = db.collection(["users", chat.friendId, "chatActive"].joined(separator: "/"))
        let messagesRef = collectionRequestRef.document(chat.friendId).collection("messages")
        let activeMessageRef = collectionActiveRef.document(chat.friendId).collection("messages")
        let friendActiveMessageRef = collectionFriendActiveRef.document(forUser.uid).collection("messages")
        
        getAlldocument(type: MMessage.self, collection: messagesRef) { allMessages in
    
            deleteCollection(collection: messagesRef)
            collectionRequestRef.document(chat.friendId).delete()
            
            //add chat document to current user
            do {
                try collectionActiveRef.document(chat.friendId).setData(from: chat)
            } catch {
                fatalError("Cant convert from chat data to FirestoreData")
            }
            
            //add all message to collection "messages" in  chat document
            allMessages.forEach { message in
                var currentMessageRef: DocumentReference
                do {
                    //add message to current user
                    try currentMessageRef = activeMessageRef.addDocument(from: message)
                    //set current path to ID message
                    currentMessageRef.setData([MMessage.CodingKeys.id.rawValue : currentMessageRef], merge: true)
                } catch {
                    fatalError("Cant convert from message data to FirestoreData")
                }
                
                do {
                    //add message to friend user
                    try currentMessageRef = friendActiveMessageRef.addDocument(from: message)
                    //set current path to ID message
                    currentMessageRef.setData([MMessage.CodingKeys.id.rawValue : currentMessageRef], merge: true)
                } catch {
                    fatalError("Cant convert from message data to FirestoreData")
                }
            }
        }
    }
}

//MARK: getAlldocument
private func getAlldocument<T:Codable>(type: T.Type ,collection: CollectionReference, complition:@escaping([T])-> Void) {
    
    var elements = [T]()
    var element: T?
    collection.getDocuments { snapshot, error in
        guard let snapshot = snapshot else { fatalError("Cant get collection snapshot")}
        
        snapshot.documents.forEach { document in
            do {
                try element = document.data(as: T.self)
                guard let message = element else { fatalError("message is nil")}
                elements.append(message)
            } catch {
                fatalError("Cant convert data to MMessage")
            }
        }
        complition(elements)
    }
}

//MARK: deleteCollection
//with inside document
private func  deleteCollection(collection: CollectionReference, batchSize: Int = 100) {
    // Limit query to avoid out-of-memory errors on large collections.
    // When deleting a collection guaranteed to fit in memory, batching can be avoided entirely.
    collection.limit(to: batchSize).getDocuments { docset, error in
        // An error occurred.
        guard let docset = docset else { fatalError("Cant get collection") }
        
        let batch = collection.firestore.batch()
        docset.documents.forEach { batch.deleteDocument($0.reference) }
        
        batch.commit {_ in
            //   self.deleteCollection(collection: collection, batchSize: batchSize)
        }
    }
}



