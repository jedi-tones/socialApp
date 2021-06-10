//
//  EditProfileViewDelegate.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

protocol EditProfileViewDelegate: class {
    func editPhotosButtonTap()
    func genderSelectTapped(selectedGender: String)
    func sexualitySelectTapped(selectedSexuality: String)
    func incognitoSwitchChanged()
    func previewTapped()
}
