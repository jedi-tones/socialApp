//
//  FireStoreServiceExtensionAdmin.swift
//  socialApp
//
//  Created by Денис Щиголев on 24.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseFirestore
import GeoFire

extension FirestoreService {
    
    //MARK: backupAllusers
    func backupAllusers( complition: @escaping (Result<[MPeople],Error>) -> Void) {
        var allUsers: [MPeople] = []
        let backupUsersRef = db.collection("backUpUsers")
        
        usersReference.getDocuments {[unowned self] querySnapshot, error in
            if let error = error {
                complition(.failure(error))
            } else {
                querySnapshot?.documents.forEach({ queryDocumentSnapshot in
                    if let people = MPeople(documentSnap: queryDocumentSnapshot) {
                        
                        allUsers.append(people)
                    }
                })
                
                let maxBatchSize = 500
                let chunkedAllUsers = allUsers.chunked(into: maxBatchSize)
                
                for (index, peoples) in chunkedAllUsers.enumerated() {
                    let batch = db.batch()
                    peoples.forEach { mpeople in
                        let peopleDocRef = backupUsersRef.document(mpeople.senderId)
                        do {
                            try batch.setData(from: mpeople, forDocument: peopleDocRef)
                        } catch {
                            complition(.failure(error))
                        }
                    }
                    batch.commit { error in
                        if let error = error {
                            complition(.failure(error))
                        } else {
                            if index == chunkedAllUsers.count - 1 {
                                complition(.success(allUsers))
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK: updateGeoHashForAllUSer
    func updateGeoHashForAllUSer( complition: @escaping (Result<[String],Error>) -> Void) {
        
        var allUsers: [MPeople] = []
        
        usersReference.getDocuments {[unowned self] querySnapshot, error in
            if let error = error {
                complition(.failure(error))
            } else {
                querySnapshot?.documents.forEach({ queryDocumentSnapshot in
                    if var people = MPeople(documentSnap: queryDocumentSnapshot) {
                        let geohash = GFUtils.geoHash(forLocation: people.location, withPrecision: 20)
                        people.geohash = geohash
                        allUsers.append(people)
                    }
                })
                
                let maxBatchSize = 500
                let chunkedAllUsers = allUsers.chunked(into: maxBatchSize)
                
                for (index, peoples) in chunkedAllUsers.enumerated() {
                    let batch = db.batch()
                    peoples.forEach { mpeople in
                        batch.setData([MPeople.CodingKeys.geohash.rawValue : mpeople.geohash],
                                      forDocument: usersReference.document(mpeople.senderId),
                                      merge: true)
                        batch.setData([MPeople.CodingKeys.location.rawValue : [MLocation.geohash.rawValue: FieldValue.delete()]],
                                       forDocument: usersReference.document(mpeople.senderId),
                                       merge: true)
                    }
                    batch.commit { error in
                        if let error = error {
                            complition(.failure(error))
                        } else {
                            if index == chunkedAllUsers.count - 1 {
                                complition(.success(allUsers.map({$0.senderId})))
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func getPeopleCount() {
       
    }
}
