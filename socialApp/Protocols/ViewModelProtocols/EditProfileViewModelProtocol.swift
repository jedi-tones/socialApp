//
//  EditProfileViewModelProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

protocol EditProfileViewModelProtocol {
    
    var currentPeopleDelegate: CurrentPeopleDataDelegate? { get set }
    var currentPeople: Box<MPeople> { get }
    func editProfileViewViewModel() -> EditProfileViewViewModelProtocol
    func firestoreSaveProfileAfterEditViewModel(editedPeople: MPeople) -> FirestoreSaveProfileAfterEditViewModelProtocol
}
