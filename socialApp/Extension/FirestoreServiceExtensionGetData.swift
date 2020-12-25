//
//  FirestoreExtensionGetData.swift
//  socialApp
//
//  Created by Денис Щиголев on 19.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GeoFire

extension FirestoreService {
    
    //MARK: getPeoplePaginate
    func getPeoplePaginate(currentPeople: MPeople,
                           likeChat: [MChat],
                           dislikeChat: [MDislike],
                           acceptChat: [MChat],
                           reports: [MReports],
                           complition: @escaping(Result<[MPeople], Error>)-> Void) {
        
        let likeChatID = likeChat.map { chat -> String in
            chat.friendId
        }
        let dislikeChatID = dislikeChat.map { dislikeChat -> String in
            dislikeChat.dislikePeopleID
        }
        let acceptChatID = acceptChat.map { chat -> String in
            chat.friendId
        }
        let reportsID = reports.map { report -> String in
            report.reportUserID
        }
        
        var usersID = likeChatID + dislikeChatID + acceptChatID + reportsID
        usersID.append(currentPeople.senderId)
        
        let minRange = currentPeople.searchSettings[MSearchSettings.minRange.rawValue] ?? MSearchSettings.minRange.defaultValue
        let maxRange = currentPeople.searchSettings[MSearchSettings.maxRange.rawValue] ?? MSearchSettings.maxRange.defaultValue
        
        var needCheckActiveUser = MSearchSettings.onlyActive.defaultValue == 0 ? false : true
        if let currentPeopleSettings = currentPeople.searchSettings[MSearchSettings.onlyActive.rawValue]  {
            needCheckActiveUser = currentPeopleSettings == 0 ? false : true
        }
        
       
        let radiusSearch = currentPeople.searchSettings[MSearchSettings.distance.rawValue] ?? MSearchSettings.distance.defaultValue
       
        //geohash search has
        //The latitude of  GeoPoint in the range [-90, 90].
        //The longitude of  GeoPoint in the range [-180, 180].
        //with large search area, need search without geohash
        if radiusSearch <= 1000 {
            
            searchPeopleWithGeoHash(radiusSearch: radiusSearch,
                                    usersID: usersID,
                                    minRange: minRange,
                                    maxRange: maxRange,
                                    needCheckActiveUser: needCheckActiveUser,
                                    currentPeople: currentPeople) { result in
                switch result {
                
                case .success(let mPeoples):
                    print("search WithGeoHash")
                    complition(.success(mPeoples))
                case .failure(let error):
                    complition(.failure(error))
                }
            }
        } else {
            searchPeopleWithoutGeoHash(radiusSearch: radiusSearch,
                                    usersID: usersID,
                                    minRange: minRange,
                                    maxRange: maxRange,
                                    needCheckActiveUser: needCheckActiveUser,
                                    currentPeople: currentPeople) { result in
                switch result {
                
                case .success(let mPeoples):
                    print("search WithoutGeoHash")
                    complition(.success(mPeoples))
                case .failure(let error):
                    complition(.failure(error))
                }
            }
        }
    }
    
    //MARK: search WithGeoHash
    private func searchPeopleWithGeoHash(radiusSearch: Int,
                                         usersID: [String],
                                         minRange: Int,
                                         maxRange: Int,
                                         needCheckActiveUser: Bool,
                                         currentPeople: MPeople,
                                         complition: @escaping(Result<[MPeople], Error>)-> Void) {
        
        var peopleNearby: [MPeople] = []
        
        let centerLocation = currentPeople.location
        let metrIntoKmScale = 1000
        let diametrToRadiusScale = 2
        let geoRadius = radiusSearch * metrIntoKmScale / diametrToRadiusScale
        
        //set bounds of location
        let queryBounds = GFUtils.queryBounds(forLocation: centerLocation,
                                              withRadius: Double(geoRadius))
    
        
        let queries = queryBounds.compactMap { (any) -> Query? in
            guard let bound = any as? GFGeoQueryBounds else { return nil }
            return usersReference
                .order(by: MPeople.CodingKeys.geohash.rawValue)
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
        }
        
        var compliteGetDataQueries = 0 {
            didSet {
                if compliteGetDataQueries == queries.count {
                    complition(.success(peopleNearby))
                }
            }
        }
        
        for (index, query) in queries.enumerated() {
            query
                .whereField(MPeople.CodingKeys.isActive.rawValue, isEqualTo: true)
                .whereField(MPeople.CodingKeys.isBlocked.rawValue, isEqualTo: false)
                .whereField(MPeople.CodingKeys.isIncognito.rawValue, isEqualTo: false)
                .whereField(MPeople.CodingKeys.gender.rawValue, isEqualTo: MLookingFor.compareGender(gender: currentPeople.lookingFor))
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        complition(.failure(error))
                    } else {
                    guard let snapshot = querySnapshot else {
                        complition(.failure(FirestoreError.snapshotNotExist))
                        return
                    }
                        print("document count \(snapshot.documents.count)")
                    snapshot.documents.forEach { queryDocumentSnapshot in
                        if var people = MPeople(documentSnap: queryDocumentSnapshot) {
                            
                            //check distance to people and append to him
                            //let distance = LocationService.shared.getDistance(currentPeople: currentPeople, newPeople: people)
                            let distance = GFUtils.distance(from: CLLocation(latitude: currentPeople.location.latitude,
                                                                             longitude: currentPeople.location.longitude),
                                                            to: CLLocation(latitude: people.location.latitude,
                                                                           longitude: people.location.longitude))
                            
                            let distanceKM = Int(distance / 1000)
                            people.distance = distanceKM
                            //check dateOfBirth
                            let age = people.dateOfBirth.getAge()
                            //check is active
                            if needCheckActiveUser {
                                guard  people.lastActiveDate.checkIsActiveUser() else { return }
                            }
                            //check current people not in users array
                            guard !usersID.contains(people.senderId) else { return }
                            //check distance and age
                            if age >= minRange && age <= maxRange && distanceKM <= radiusSearch {
                                peopleNearby.append(people)
                                print("people \(people.displayName)")
                            }
                        }
                        print("\n index \(index) people  count \(peopleNearby.count)")
                    }
                    compliteGetDataQueries += 1
                }
            }
        }
    }
    
    //MARK: search WithoutGeoHash
    private func searchPeopleWithoutGeoHash(radiusSearch: Int,
                                            usersID: [String],
                                            minRange: Int,
                                            maxRange: Int,
                                            needCheckActiveUser: Bool,
                                            currentPeople: MPeople,
                                            complition: @escaping(Result<[MPeople], Error>)-> Void) {
        
        var peopleNearby: [MPeople] = []
        
        usersReference
            .whereField(MPeople.CodingKeys.isActive.rawValue, isEqualTo: true)
            .whereField(MPeople.CodingKeys.isBlocked.rawValue, isEqualTo: false)
            .whereField(MPeople.CodingKeys.isIncognito.rawValue, isEqualTo: false)
            .whereField(MPeople.CodingKeys.gender.rawValue, isEqualTo: MLookingFor.compareGender(gender: currentPeople.lookingFor))
            .order(by: MPeople.CodingKeys.geohash.rawValue, descending: false)
            .getDocuments { snapshot, error in
            if let error = error {
                complition(.failure(error))
            } else {
                guard let snapshot = snapshot else {
                    complition(.failure(FirestoreError.snapshotNotExist))
                    return
                }
                snapshot.documents.forEach { queryDocumentSnapshot in
                    if var people = MPeople(documentSnap: queryDocumentSnapshot) {
                        
                        //check distance to people and append to him
                        let distance = LocationService.shared.getDistance(currentPeople: currentPeople, newPeople: people)
                        let range = currentPeople.searchSettings[MSearchSettings.distance.rawValue] ?? MSearchSettings.distance.defaultValue
                        //check dateOfBirth
                        let age = people.dateOfBirth.getAge()
                        //check is active
                        if needCheckActiveUser {
                            guard  people.lastActiveDate.checkIsActiveUser() else { return }
                        }
                        //check current people not in users array
                        guard !usersID.contains(people.senderId) else { return }
                        //check distance and age
                        if distance <= range && age >= minRange && age <= maxRange {
                            people.distance = distance
                            peopleNearby.append(people)
                        }
                    }
                }
                complition(.success(peopleNearby))
            }
        }
    }
    
    //MARK: getPeople deprecated
    func getPeople(currentPeople: MPeople,
                   likeChat: [MChat],
                   dislikeChat: [MDislike],
                   acceptChat: [MChat],
                   reports: [MReports],
                   complition: @escaping(Result<[MPeople], Error>)-> Void) {
        
        var peopleNearby: [MPeople] = []
        
        let likeChatID = likeChat.map { chat -> String in
            chat.friendId
        }
        let dislikeChatID = dislikeChat.map { dislikeChat -> String in
            dislikeChat.dislikePeopleID
        }
        let acceptChatID = acceptChat.map { chat -> String in
            chat.friendId
        }
        let reportsID = reports.map { report -> String in
            report.reportUserID
        }
        
        var usersID = likeChatID + dislikeChatID + acceptChatID + reportsID
        usersID.append(currentPeople.senderId)
        
        let minRange = currentPeople.searchSettings[MSearchSettings.minRange.rawValue] ?? MSearchSettings.minRange.defaultValue
        let maxRange = currentPeople.searchSettings[MSearchSettings.maxRange.rawValue] ?? MSearchSettings.maxRange.defaultValue
       
        var needCheckActiveUser = MSearchSettings.onlyActive.defaultValue == 0 ? false : true
        if let currentPeopleSettings = currentPeople.searchSettings[MSearchSettings.onlyActive.rawValue]  {
            needCheckActiveUser = currentPeopleSettings == 0 ? false : true
        }
       
   
        usersReference.whereField(
            MPeople.CodingKeys.isActive.rawValue, isEqualTo: true
        ).whereField(
            MPeople.CodingKeys.isBlocked.rawValue, isEqualTo: false
        ).whereField(
            MPeople.CodingKeys.isIncognito.rawValue, isEqualTo: false
        ).whereField(
            MPeople.CodingKeys.gender.rawValue, isEqualTo: MLookingFor.compareGender(gender: currentPeople.lookingFor)
        ).getDocuments { snapshot, error in
            if let error = error {
                complition(.failure(error))
            } else {
                guard let snapshot = snapshot else {
                    complition(.failure(FirestoreError.snapshotNotExist))
                    return
                }
                snapshot.documents.forEach { queryDocumentSnapshot in
                    if var people = MPeople(documentSnap: queryDocumentSnapshot) {
                        
                        //check distance to people and append to him
                        let distance = LocationService.shared.getDistance(currentPeople: currentPeople, newPeople: people)
                        let range = currentPeople.searchSettings[MSearchSettings.distance.rawValue] ?? MSearchSettings.distance.defaultValue
                        //check dateOfBirth
                        let age = people.dateOfBirth.getAge()
                        //check is active
                        if needCheckActiveUser {
                            guard  people.lastActiveDate.checkIsActiveUser() else { return }
                        }
                        //check current people not in users array
                        guard !usersID.contains(people.senderId) else { return }
                        //check distance and age
                        if distance <= range && age >= minRange && age <= maxRange {
                            people.distance = distance
                            peopleNearby.append(people)
                        }
                    }
                }
                complition(.success(peopleNearby))
            }
        }
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
    
    //MARK: getUserCollection
    func getUserCollection(userID: String, collection: MFirestorCollection, complition: @escaping(Result<[MChat], Error>)->Void) {
        
        let reference = usersReference.document(userID).collection(collection.rawValue)
        var chats: [MChat] = []
        reference.getDocuments { snapshot, error in
            if let error = error {
                complition(.failure(error))
            }
            guard let snapshot = snapshot else {
                complition(.failure(FirestoreError.snapshotNotExist))
                return
            }
            snapshot.documents.forEach({ queryDocumentSnapshot in
                if let chat = MChat(documentSnap: queryDocumentSnapshot) {
                    chats.append(chat)
                }
            })
            complition(.success(chats))
        }
    }
    
    func getAllMessagesInChat(currentUserID: String,
                              firstLoadMessage: MMessage? = nil,
                              chat: MChat,
                              complition: @escaping (Result<[MMessage],Error>)-> Void) {
        var reference = usersReference
            .document(currentUserID)
            .collection(MFirestorCollection.acceptChats.rawValue)
            .document(chat.friendId)
            .collection(MFirestorCollection.messages.rawValue)
            .order(by: MMessage.CodingKeys.sentDate.rawValue, descending: true)
            .limit(to: 20)
        
        if let firstLoadMessage = firstLoadMessage {
            reference = usersReference
                .document(currentUserID)
                .collection(MFirestorCollection.acceptChats.rawValue)
                .document(chat.friendId)
                .collection(MFirestorCollection.messages.rawValue)
                .order(by: MMessage.CodingKeys.sentDate.rawValue, descending: true)
                .start(after: [Timestamp(date: firstLoadMessage.sentDate)])
                .limit(to: 20)
        }
        
        var messages: [MMessage] = []
        
        reference.getDocuments { querySnapshot, error in
            if let error = error {
                complition(.failure(error))
            } else {
                querySnapshot?.documents.forEach({ queryDocumentSnapshot in
                    guard var message = MMessage(documentSnap: queryDocumentSnapshot) else {
                        complition(.failure(MessageError.getMessageData))
                        return
                    }
                    //need set image, for change message type in MMessage
                    if message.imageURL != nil {
                        message.image = #imageLiteral(resourceName: "imageSend")
                    }
                    messages.append(message)
                })
                complition(.success(messages))
            }
        }
    }
    
    //MARK: getDislikes
    func getDislikes(userID: String, complition: @escaping(Result<[MDislike],Error>)->Void) {
        let reference = usersReference.document(userID).collection(MFirestorCollection.dislikePeople.rawValue)
        var dislikes: [MDislike] = []
        reference.getDocuments { snapshot, error in
            if let error = error {
                complition(.failure(error))
            }
            guard let snapshot = snapshot else {
                complition(.failure(FirestoreError.snapshotNotExist))
                return
            }
            snapshot.documents.forEach({ queryDocumentSnapshot in
                if let dislike = MDislike(documentSnap: queryDocumentSnapshot) {
                    dislikes.append(dislike)
                }
            })
            complition(.success(dislikes))
        }
    }
    
    //MARK: getReports
    func getReports(userID: String, complition: @escaping(Result<[MReports],Error>)->Void) {
        let reference = usersReference.document(userID).collection(MFirestorCollection.reportUser.rawValue)
        var reports: [MReports] = []
        reference.getDocuments { snapshot, error in
            if let error = error {
                complition(.failure(error))
            }
            guard let snapshot = snapshot else {
                complition(.failure(FirestoreError.snapshotNotExist))
                return
            }
            snapshot.documents.forEach({ queryDocumentSnapshot in
                if let report = MReports(documentSnap: queryDocumentSnapshot) {
                    reports.append(report)
                }
            })
            complition(.success(reports))
        }
    }
}
