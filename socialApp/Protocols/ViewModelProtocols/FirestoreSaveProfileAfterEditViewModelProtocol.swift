//
//  FirestoreSaveProfileAfterEditViewModelProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

protocol FirestoreSaveProfileAfterEditViewModelProtocol {
    var id: String { get }
    var displayName: String { get }
    var advert: String { get }
    var gender: String { get }
    var sexuality: String { get }
    var interests: [String] { get }
    var desires: [String] { get }
    var isIncognito: Bool { get }
}
