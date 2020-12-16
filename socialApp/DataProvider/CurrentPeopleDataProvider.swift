//
//  CurrentPeopleDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 16.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class CurrentPeopleDataProvider {
    
    var currentPeople: MPeople
    
    init(currentPeople: MPeople) {
        self.currentPeople = currentPeople
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setup() {
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(currentUserUserDefaultUpdate))
    }
    
    @objc private func currentUserUserDefaultUpdate() {
        if let people = UserDefaultsService.shared.getMpeople() {
            currentPeople = people
        } else {
            PopUpService.shared.showInfo(text: UserDefaultsError.cantGetData.localizedDescription)
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
    
    func savePeopleDataToUserDefaults(currentPeople: MPeople) {
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
        self.currentPeople = currentPeople
    }
    
    func updatePeopleDataFromFirestore(complition:@escaping(Result<MPeople,Error>) -> Void) {
        FirestoreService.shared.getUserData(userID: currentPeople.senderId) {[unowned self] result in
            switch result {
            
            case .success(let people):
                currentPeople = people
                complition(.success(people))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
}
