//
//  CurrentPeopleDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 16.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation
import MapKit

class CurrentPeopleDataProvider {
    
    var currentPeople: MPeople
    
    init() {
        self.currentPeople = MPeople()
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setup() {
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(currentUserUserDefaultUpdate))
        NotificationCenter.addObsorverToFCMKeyUpdate(observer: self, selector: #selector(fcmKeyIsUpdated(notification:)))
    }
    
    private func setEmptyCurrentPeople()  {
        currentPeople = MPeople()
    }
    
    @objc private func currentUserUserDefaultUpdate() {
        if let people = UserDefaultsService.shared.getMpeople() {
            currentPeople = people
        } else {
            PopUpService.shared.showInfo(text: UserDefaultsError.cantGetData.localizedDescription)
        }
    }
    
    @objc private func fcmKeyIsUpdated(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: String],
              let fcmKey = userInfo[PushMessagingService.shared.notificationName],
              fcmKey != currentPeople.fcmKey else { return }
        
        FirestoreService.shared.saveFCMKey(id: currentPeople.senderId,
                                           fcmKey: fcmKey) {[weak self] result in
            switch result {
            
            case .success(_):
                self?.currentPeople.fcmKey = fcmKey
                NotificationCenter.postFCMKeyInChatsNeedUpdate(data: userInfo)
            case .failure(let error):
                PopUpService.shared.showInfo(text: "Ошибка: \(error)")
            }
        }
    }
}

extension CurrentPeopleDataProvider: CurrentPeopleDataDelegate {
    
    func updatePeopleDataFromUserDefaults(complition:@escaping(Result<MPeople,Error>) -> Void) {
        if let people = UserDefaultsService.shared.getMpeople() {
            currentPeople = people
            complition(.success(people))
        } else {
            complition(.failure(UserDefaultsError.cantGetData))
        }
    }
    
    func deletePeopleFromUserDefaults() {
        setEmptyCurrentPeople()
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
    }
    
    func savePeopleDataToUserDefaults(currentPeople: MPeople) {
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
        self.currentPeople = currentPeople
    }
    
    func updatePeopleDataFromFirestore(userID: String, complition:@escaping(Result<MPeople,Error>) -> Void) {
        FirestoreService.shared.getUserData(userID: userID) {[unowned self] result in
            switch result {
            
            case .success(let people):
                UserDefaultsService.shared.saveMpeople(people: people)
                currentPeople = people
                complition(.success(people))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
}
