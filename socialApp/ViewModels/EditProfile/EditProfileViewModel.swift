//
//  EditProfileViewModel.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class EditProfileViewModel: EditProfileViewModelProtocol {

    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    
    var currentPeople: Box<MPeople> {
        if let currentPeopleDelegate = currentPeopleDelegate {
            let boxValue = Box(value: currentPeopleDelegate.currentPeople)
            return boxValue
        } else {
            fatalError("currentPeopleDelegate is nil on EditProfileViewModel")
        }
    }
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?) {
        self.currentPeopleDelegate = currentPeopleDelegate
    }
    
    
    func editProfileViewViewModel() -> EditProfileViewViewModelProtocol {
        
        let editProfileViewViewModel = EditProfileViewViewModel(currentPeople: currentPeople.value)
        return editProfileViewViewModel
    }
    
    func firestoreSaveProfileAfterEditViewModel(editedPeople: MPeople) -> FirestoreSaveProfileAfterEditViewModelProtocol {
        FirestoreSaveProfileAfterEditViewModel(people: editedPeople)
    }
}
