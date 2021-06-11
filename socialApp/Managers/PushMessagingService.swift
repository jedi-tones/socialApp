//
//  MessagingService.swift
//  socialApp
//
//  Created by Денис Щиголев on 11.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation
import FirebaseMessaging

class PushMessagingService: NSObject {
    static let shared = PushMessagingService()
    let notificationName = "firebaseMessageToken"
    
    //for auth when post request
    private let serverKey = "AAAArMXNdi0:APA91bFZsnq8l3j79_ElA0w4qUSST7ZY6k8hCkWPqdcdWuoEtH87tullSfteHahb0zMiveENxHlQnpxS5HrYXiQmXINcntcnMXqIhf_Ma9fDwdhA19PFmKY5LD3NEtEktcPmbqNLhuFq"
    
    private let sendUrlString = "https://fcm.googleapis.com/fcm/send"
    private let infoUrlString = "https://iid.googleapis.com/iid/info/"
    
    //MARK: sendMessage
    private func sendMessage(token: String?,
                             topic: String?,
                             title: String,
                             body: String,
                             category: String,
                             bageCount: Int,
                             sound: String,
                             isMutableContent: String,
                             data: [String:String]?) {
        guard let url = URL(string: sendUrlString) else { fatalError("can't cast to url")}
        
        var to = ""
        //if set token = send to token
        if let token = token {
            to = token
            //else send to topic
        } else if let topic = topic {
            to = "/topics/\(topic)"
        }
        
        let param = MPushMessage(to: to,
                                 notification: MAps(title: title,
                                                    body: body,
                                                    category: category,
                                                    badge: bageCount,
                                                    sound: sound,
                                                    mutableContent: isMutableContent),
                                 data: data)
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(param)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if let data = data {
                do {
                    let _ = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                   // print("Data received \(jsonData)")
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    private func subscribeToTopic(topic: String) {
        Messaging.messaging().subscribe(toTopic: topic)
    }
    
    private func unSubscribeToTopic(topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic)
    }
    
    //MARK: registerDelegate
    func registerDelegate() {
        Messaging.messaging().delegate = self
    }
    
    
    //MARK: getToken
    func getToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                fatalError(error.localizedDescription)
            } else if let token = token {
                print("FCM registration token: \(token)")
                
                let data = [PushMessagingService.shared.notificationName : token]
                NotificationCenter.postFCMKeyNeedUpdate(data: data)
            }
        }
    }
    
    //MARK: deleteToken
    //clear token in profile and user chats
    func deleteToken(currentPeopleID: String,
                     acceptChats: [MChat],
                     likeChats: [MChat],
                     complition: @escaping(Result<(),Error>)->Void) {
        let clearFCMKey = ""
        //clear key in profile
        FirestoreService.shared.saveFCMKey(id: currentPeopleID,
                                           fcmKey: clearFCMKey) { result in
            switch result {
            
            case .success(_):
                
                //clear key in chats
                FirestoreService.shared.updateFCMKeyInChats(id: currentPeopleID,
                                                            fcmKey: clearFCMKey,
                                                            acceptChats: acceptChats) { result in
                    switch result {
                    
                    case .success(_):
                        complition(.success(()))
                    case .failure(let error):
                        complition(.failure(error))
                    }
                }
                
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
}
//MARK: -  subscribe / unsubscribe
extension PushMessagingService {
    
    func subscribeMainTopic() {
        subscribeToTopic(topic: MTopics.allDevice.rawValue)
        subscribeToTopic(topic: MTopics.news.rawValue)
    }
    
    //deprecated main topic unsubscribe
    func unSubscribeMainTopic(userID: String) {
        let myIDTopic = userID.replacingOccurrences(of: "@", with: "_")
        unSubscribeToTopic(topic: MTopics.allDevice.rawValue)
        unSubscribeToTopic(topic: MTopics.news.rawValue)
        unSubscribeToTopic(topic: myIDTopic)
    }
    
    //deprecated topic subscribe
    func logInSubscribe(currentUserID: String, acceptChats: [MChat], likeChats: [MChat]) {
        let myIDTopic = currentUserID.replacingOccurrences(of: "@", with: "_")
        subscribeToTopic(topic: myIDTopic)
        //subscribe all chats
        acceptChats.forEach { chat in
            subscribeToChatNotification(currentUserID: currentUserID,
                                        chatUserID: chat.friendId)
        }
        //subscribe all likeChats
        likeChats.forEach { chat in
        subscribeToChatNotification(currentUserID: currentUserID,
                                    chatUserID: chat.friendId)
        }
    }
    
    //deprecated topic unsubscribe
    func logOutUnsabscribe(currentUserID: String, acceptChats: [MChat]) {
        //unsubscribe current user topic
        let myIDTopic = currentUserID.replacingOccurrences(of: "@", with: "_")
        unSubscribeToTopic(topic: myIDTopic)
        //unsubscribe all chats
        acceptChats.forEach { chat in
            unSubscribeToChatNotification(currentUserID: currentUserID,
                                          chatUserID: chat.friendId)
        }
    }
    
    //deprecated topic subscribe
    func subscribeToChatNotification(currentUserID: String, chatUserID: String){
        let topic = [currentUserID, chatUserID].joined(separator: "_")
        let correctTopic = topic.replacingOccurrences(of: "@", with: "_")
        
        subscribeToTopic(topic: correctTopic)
    }
    
    //deprecated topic unsubscribe
    func unSubscribeToChatNotification(currentUserID: String, chatUserID: String){
        let topic = [currentUserID, chatUserID].joined(separator: "_")
        let correctTopic = topic.replacingOccurrences(of: "@", with: "_")
        
        unSubscribeToTopic(topic: correctTopic)
    }
}

//MARK: - send message
extension PushMessagingService {
    //deprecated topic send
    func sendPushMessageToUser(userID: String, header: String, text: String, category: MActionType) {
        let topic = userID.replacingOccurrences(of: "@", with: "_")
        
        sendMessage(token: nil,
                    topic: topic,
                    title: header,
                    body: text,
                    category: category.rawValue,
                    bageCount: 1,
                    sound: "default",
                    isMutableContent: "true",
                    data: nil)
    }
    //deprecated topic send
    func sendMessageToUser(currentUser: MPeople, toUserID: MChat, header: String, text: String) {
        let topic = [toUserID.friendId, currentUser.senderId].joined(separator: "_")
        let correctTopic = topic.replacingOccurrences(of: "@", with: "_")
        
        sendMessage(token: nil,
                    topic: correctTopic,
                    title: header,
                    body: text,
                    category: MActionType.message.rawValue,
                    bageCount: 1,
                    sound: "default",
                    isMutableContent: "true",
                    data: nil)
    }
    
    func sendPushMessageToToken(token: String, header: String, text: String, category: MActionType) {
        
        sendMessage(token: token,
                    topic: nil,
                    title: header,
                    body: text,
                    category: category.rawValue,
                    bageCount: 1,
                    sound: "zenRequestAlert.caf",
                    isMutableContent: "true",
                    data: nil)
    }
    
    func sendChatMessageToToken(token: String, chatFriendID: String, header: String, text: String) {
        
        let data = [MDeeplinkTypes.chat(friendID: "").description : chatFriendID]
        
        sendMessage(token: token,
                    topic: nil,
                    title: header,
                    body: text,
                    category: MActionType.message.rawValue,
                    bageCount: 1,
                    sound: "messageAlert.caf",
                    isMutableContent: "true",
                    data: data)
        
    }
}

//MARK: - MessagingDelegate
extension PushMessagingService: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        print("\n FCM registration token: \(fcmToken) \n")
    }
}
