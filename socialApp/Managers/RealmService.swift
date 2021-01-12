//
//  RealmService.swift
//  socialApp
//
//  Created by Денис Щиголев on 12.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import RealmSwift

class RealmService {
    
    private let realm = try! Realm()
    
    func appendToRealm<T: Object>(object: T, complition: @escaping(Result<T, Error>) -> Void) {
        do {
            try realm.write {
                realm.add(object, update: .all)
                complition(.success(object))
            }
        } catch {
            complition(.failure(error))
        }
    }
    
    func deleteFromRealm<T: Object>(object: T, complition: @escaping(Result<T, Error>) -> Void) {
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            complition(.failure(error))
        }
    }
    
    func getObject<T: Object>(objectType: T.Type, predicate: NSPredicate? = nil) -> Results<T>  {
        if let predicate = predicate {
            return realm.objects(objectType).filter(predicate)
        } else {
            return realm.objects(objectType)
        }
    }
}
