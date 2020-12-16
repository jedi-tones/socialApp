//
//  CurrentPeopleDataDelegate.swift
//  socialApp
//
//  Created by Денис Щиголев on 16.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

protocol CurrentPeopleDataDelegate: class {
    var currentPeople: MPeople { get set }
    func savePeopleDataToUserDefaults(currentPeople: MPeople)
    func updatePeopleDataFromUserDefaults(complition:@escaping(Result<MPeople,Error>) -> Void)
    func updatePeopleDataFromFirestore(complition:@escaping(Result<MPeople,Error>) -> Void)
}
