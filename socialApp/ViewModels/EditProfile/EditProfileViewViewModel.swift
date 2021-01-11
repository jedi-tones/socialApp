//
//  EditProfileViewViewModel.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class EditProfileViewViewModel: EditProfileViewViewModelProtocol {

    var currentPeople: MPeople
    
    var interests: [String]
    var desires: [String]
    var userImage: String
    var gallery: [String : MGalleryPhotoProperty]
    var displayName: String
    var advert: String
    var gender: String
    var sexuality: String
    var isIncognito: Bool
    let isTestUser: Bool
    let id: String
    
    init(currentPeople: MPeople) {
        self.currentPeople = currentPeople
        
        id = currentPeople.senderId
        interests = currentPeople.interests
        desires = currentPeople.desires
        userImage = currentPeople.userImage
        gallery = currentPeople.gallery
        displayName = currentPeople.displayName
        advert = currentPeople.advert
        gender = currentPeople.gender
        sexuality = currentPeople.sexuality
        isIncognito = currentPeople.isIncognito
        isTestUser = currentPeople.isTestUser
    }
}
