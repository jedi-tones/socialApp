//
//  MChatRealm.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseFirestore

class MChatRealm: Object, Codable, ReprasentationModel {
    @objc dynamic var friendId = ""
    @objc dynamic var friendUserImageString = ""
    @objc dynamic var friendUserName = ""
    @objc dynamic var lastMessage = ""
    @objc dynamic var lastMessageSenderID = ""
    @objc dynamic var date = Date()
    @objc dynamic var unreadChatMessageCount = 0
    @objc dynamic var friendIsWantStopTimer = false
    @objc dynamic var currentUserIsWantStopTimer = false
    @objc dynamic var timerOfLifeIsStoped = false
    @objc dynamic var createChatDate = Date()
    @objc dynamic var fcmKey = ""
    @objc dynamic var friendInChat = false
    @objc dynamic var friendSawAllMessageInChat = true
    @objc dynamic var isNewChat = true
    
    let messages = List<MMessageRealm>()
    
    override static func primaryKey() -> String? {
        "friendId"
    }
    
    static func == (lhs: MChatRealm, rhs: MChatRealm) -> Bool {
        return lhs.friendId == rhs.friendId
    }
    
   
    //MARK: QueryDocumentSnapshot
    //for init with ListenerService
    required convenience init?(documentSnap: QueryDocumentSnapshot){
        self.init()
          let documet = documentSnap.data()
          
        if let friendUserName = documet["friendUserName"] as? String {
            self.friendUserName = friendUserName
        } else { return nil }
        
        if let friendUserImageString = documet["friendUserImageString"] as? String {
            self.friendUserImageString = friendUserImageString
        } else { return nil }
        
        if let lastMessageSenderID =  documet["lastMessageSenderID"] as? String {
            self.lastMessageSenderID = lastMessageSenderID
        } else { self.lastMessageSenderID = "" }
        
        if let lastMessage =  documet["lastMessage"] as? String {
            self.lastMessage = lastMessage
        } else { self.lastMessage = "" }
        
        if let isNewChat =  documet["isNewChat"] as? Bool {
            self.isNewChat = isNewChat
        } else { return nil }
        
        if let friendId = documet["friendId"] as? String {
            self.friendId = friendId
        } else { return nil }
        
        if let unreadChatMessageCount = documet["unreadChatMessageCount"] as? Int {
            self.unreadChatMessageCount = unreadChatMessageCount
        } else { return nil }
        
        if let friendIsWantStopTimer = documet["friendIsWantStopTimer"] as? Bool {
            self.friendIsWantStopTimer = friendIsWantStopTimer
        } else { return nil }
        
        if let currentUserIsWantStopTimer = documet["currentUserIsWantStopTimer"] as? Bool {
            self.currentUserIsWantStopTimer = currentUserIsWantStopTimer
        } else { return nil }
        
        if let timerOfLifeIsStoped = documet["timerOfLifeIsStoped"] as? Bool {
            self.timerOfLifeIsStoped = timerOfLifeIsStoped
        } else { return nil }
        
        if let createChatDate = documet["createChatDate"] as? Timestamp {
            self.createChatDate = createChatDate.dateValue()
        } else { return nil }
        
        if let fcmKey = documet["fcmKey"] as? String {
            self.fcmKey = fcmKey
        } else { self.fcmKey = "" }
        
        if let friendInChat = documet["friendInChat"] as? Bool {
            self.friendInChat = friendInChat
        } else { self.friendInChat = false }
        
        if let friendSawAllMessageInChat = documet["friendSawAllMessageInChat"] as? Bool {
            self.friendSawAllMessageInChat = friendSawAllMessageInChat
        } else { self.friendSawAllMessageInChat = true }
        
        if let date = documet["date"] as? Timestamp {
            self.date = date.dateValue()
        } else { return nil }
      }
    
    //MARK: DocumentSnapshot
    //for get document from Firestore
    required convenience init?(documentSnap: DocumentSnapshot){
        self.init()
        guard let documet = documentSnap.data()  else { return nil }
          
        if let friendUserName = documet["friendUserName"] as? String {
            self.friendUserName = friendUserName
        } else { return nil }
        
        if let friendUserImageString = documet["friendUserImageString"] as? String {
            self.friendUserImageString = friendUserImageString
        } else { return nil }
        
        if let lastMessage =  documet["lastMessage"] as? String {
            self.lastMessage = lastMessage
        } else { return nil }
        
        if let lastMessageSenderID =  documet["lastMessageSenderID"] as? String {
            self.lastMessageSenderID = lastMessageSenderID
        } else { self.lastMessageSenderID = "" }
        
        if let isNewChat =  documet["isNewChat"] as? Bool {
            self.isNewChat = isNewChat
        } else { return nil }
        
        if let friendId = documet["friendId"] as? String {
            self.friendId = friendId
        } else { return nil }
        
        if let unreadChatMessageCount = documet["unreadChatMessageCount"] as? Int {
            self.unreadChatMessageCount = unreadChatMessageCount
        } else { return nil }
        
        if let friendIsWantStopTimer = documet["friendIsWantStopTimer"] as? Bool {
            self.friendIsWantStopTimer = friendIsWantStopTimer
        } else { return nil }
        
        if let currentUserIsWantStopTimer = documet["currentUserIsWantStopTimer"] as? Bool {
            self.currentUserIsWantStopTimer = currentUserIsWantStopTimer
        } else { return nil }
        
        if let timerOfLifeIsStoped = documet["timerOfLifeIsStoped"] as? Bool {
            self.timerOfLifeIsStoped = timerOfLifeIsStoped
        } else { return nil }
        
        if let createChatDate = documet["createChatDate"] as? Timestamp {
            self.createChatDate = createChatDate.dateValue()
        } else { return nil }
        
        if let fcmKey = documet["fcmKey"] as? String {
            self.fcmKey = fcmKey
        } else { self.fcmKey = "" }
        
        if let friendInChat = documet["friendInChat"] as? Bool {
            self.friendInChat = friendInChat
        } else { self.friendInChat = false }
        
        if let friendSawAllMessageInChat = documet["friendSawAllMessageInChat"] as? Bool {
            self.friendSawAllMessageInChat = friendSawAllMessageInChat
        } else { self.friendSawAllMessageInChat = true }
        
        if let date = documet["date"] as? Timestamp {
            self.date = date.dateValue()
        } else { return nil }
      }
    
    //MARK: reprasentation
    var reprasentation: [String:Any] {
        let rep:[String: Any] = [
            "friendUserName": friendUserName,
            "friendUserImageString": friendUserImageString,
            "lastMessage": lastMessage,
            "lastMessageSenderID": lastMessageSenderID,
            "isNewChat": isNewChat,
            "friendId": friendId,
            "unreadChatMessageCount": unreadChatMessageCount,
            "friendIsWantStopTimer": friendIsWantStopTimer,
            "currentUserIsWantStopTimer": currentUserIsWantStopTimer,
            "timerOfLifeIsStoped": timerOfLifeIsStoped,
            "createChatDate": createChatDate,
            "fcmKey": fcmKey,
            "friendInChat": friendInChat,
            "friendSawAllMessageInChat": friendSawAllMessageInChat,
            "date": date
        ]
        return rep
    }
    
    //MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case friendUserName
        case friendUserImageString
        case lastMessage
        case lastMessageSenderID
        case isNewChat
        case friendId
        case unreadChatMessageCount
        case friendIsWantStopTimer
        case currentUserIsWantStopTimer
        case timerOfLifeIsStoped
        case createChatDate
        case fcmKey
        case friendInChat
        case friendSawAllMessageInChat
        case date
    }
    
  
    
    static func getDefaultPeriodMinutesOfLifeChat() -> Int {
        //period of life is 1440 minute = 1 day
        1440
    }
    
    func contains(element: String?) -> Bool {
        guard let element = element else { return true }
        if element.isEmpty { return true }
        
        let lowercasedElement = element.lowercased()
        
        return friendUserName.lowercased().contains(lowercasedElement)
    }
    
    func containsID(ID: String?) -> Bool {
        guard let ID = ID else { return false }
        
        let lowercasedID = ID.lowercased()
        
        return friendId.lowercased().contains(lowercasedID)
    }
}
