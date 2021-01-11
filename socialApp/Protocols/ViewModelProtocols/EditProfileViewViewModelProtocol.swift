//
//  EditProfileViewViewModelProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

protocol EditProfileViewViewModelProtocol {
    var currentPeople: MPeople { get set }
    
    var id: String { get }
    var interests: [String] { get set }
    var desires: [String] { get set }
    var userImage: String { get set }
    var gallery: [String : MGalleryPhotoProperty] { get set }
    var displayName: String { get set }
    var advert: String { get set }
    var gender: String { get set }
    var sexuality: String { get set }
    var isIncognito: Bool { get set }
    var isTestUser: Bool { get }
    
}
