//
//  BackgroundTaskManager.swift
//  socialApp
//
//  Created by Денис Щиголев on 20.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import BackgroundTasks
import UIKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private init() {}
    private var currentUserID: String?
    private var openChat: MChat?
    private var lastMessage: MMessage?
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    private var acceptChatDelegate: AcceptChatListenerDelegate?
    
    let backgroundAppRefreshTaskSchedulerIdentifier = "art.jedi-tones.flava.backgroundAppRefresh"
    
    func registerBackgroundTask() {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskSchedulerIdentifier,
                                        using: nil) {[weak self] (task) in
            print("BackgroundAppRefreshTaskScheduler is executed NOW!")
            print("Background time remaining: \(UIApplication.shared.backgroundTimeRemaining)s")
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            self?.exitCurrentOpenMessage {
                
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    func submitBackgroundTasks() {
        
        let timeDelay = 1.0
        
        do {
            let backgroundAppRefreshTaskRequest = BGAppRefreshTaskRequest(identifier: backgroundAppRefreshTaskSchedulerIdentifier)
            backgroundAppRefreshTaskRequest.earliestBeginDate = Date(timeIntervalSinceNow: timeDelay)
            try BGTaskScheduler.shared.submit(backgroundAppRefreshTaskRequest)
            print("Submitted task request")
        } catch {
            print("Failed to submit BGTask")
        }
    }
    
    
    func exitCurrentOpenMessage(complition:@escaping()->()) {
        guard let currentUserID = currentUserID,
              let openChat = openChat,
              let acceptChatDelegate = acceptChatDelegate
        else {
            complition()
            return
        }
        
        FirestoreService.shared.currentUserOpenCloseChat(currentUserID: currentUserID,
                                                         chat: openChat,
                                                         isOpen: false,
                                                         lastMessage: lastMessage) { _ in
            acceptChatDelegate.acceptChatCollectionViewDelegate = nil
            complition()
        }
        
    }
    
    func submitBackgoundTaskShort() {
        DispatchQueue.global().async { [unowned self] in
            // Request the task assertion and save the ID.
            
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
                // End the task if time expires.
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
                self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
            
            exitCurrentOpenMessage {
                // End the task assertion.
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
                self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
        }
    }
    
    func setCurrentOpenMessage(acceptChatDelegate: AcceptChatListenerDelegate?,
                               currentUserID: String,
                               openChat: MChat?,
                               lastMessage: MMessage?) {
        self.acceptChatDelegate = acceptChatDelegate
        self.currentUserID = currentUserID
        self.openChat = openChat
        self.lastMessage = lastMessage
        
    }
}

