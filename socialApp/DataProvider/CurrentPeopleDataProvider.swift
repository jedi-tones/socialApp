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
        self.currentPeople = MPeople(senderId: "",
                                     displayName: "",
                                     advert: "",
                                     userImage: "",
                                     gallery: [:],
                                     mail: "",
                                     gender: "",
                                     dateOfBirth: Date(),
                                     sexuality: "",
                                     lookingFor: "",
                                     interests: [],
                                     desires: [],
                                     isGoldMember: false,
                                     goldMemberDate: nil,
                                     goldMemeberPurches: nil,
                                     likeCount: 0,
                                     lastActiveDate: Date(),
                                     lastLikeDate: Date(),
                                     isTestUser: false,
                                     isIncognito: false,
                                     isBlocked: false,
                                     isAdmin: false,
                                     isActive: false,
                                     isFakeUser: nil,
                                     reportList: [],
                                     authType: .email,
                                     searchSettings: [:],
                                     location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                     distance: 0)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setup() {
        UserDefaultsService.shared.saveMpeople(people: currentPeople)
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(currentUserUserDefaultUpdate))
    }
    
    private func setEmptyCurrentPeople()  {
        let emptyCurrentPeople = MPeople(senderId: "",
                                         displayName: "",
                                         advert: "",
                                         userImage: "",
                                         gallery: [:],
                                         mail: "",
                                         gender: "",
                                         dateOfBirth: Date(),
                                         sexuality: "",
                                         lookingFor: "",
                                         interests: [],
                                         desires: [],
                                         isGoldMember: false,
                                         goldMemberDate: nil,
                                         goldMemeberPurches: nil,
                                         likeCount: 0,
                                         lastActiveDate: Date(),
                                         lastLikeDate: Date(),
                                         isTestUser: false,
                                         isIncognito: false,
                                         isBlocked: false,
                                         isAdmin: false,
                                         isActive: false,
                                         isFakeUser: nil,
                                         reportList: [],
                                         authType: .email,
                                         searchSettings: [:],
                                         location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                         distance: 0)
      currentPeople = emptyCurrentPeople
        
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
