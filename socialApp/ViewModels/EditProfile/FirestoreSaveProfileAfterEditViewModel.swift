//
//  FirestoreSaveProfileAfterEditViewModel.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class FirestoreSaveProfileAfterEditViewModel: FirestoreSaveProfileAfterEditViewModelProtocol {
    
    var id: String
    var displayName: String
    var advert: String
    var gender: String
    var sexuality: String
    var interests: [String]
    var desires: [String]
    var isIncognito: Bool
    
    init(people: MPeople) {
        id = people.senderId
        displayName = people.displayName
        advert = people.advert
        gender = people.gender
        sexuality = people.sexuality
        interests = people.interests
        desires = people.desires
        isIncognito = people.isIncognito
    }
}
