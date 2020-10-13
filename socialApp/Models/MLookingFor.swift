//
//  MLookingFor.swift
//  socialApp
//
//  Created by Денис Щиголев on 11.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

enum MLookingFor: String, CaseIterable {
    case female = "Девушку"
    case male = "Парня"
    case agender = "Agender"
    case androgyne = "Androgyne"
    case androgynous = "Androgynous"
    case bigender = "Bigender"
    case genderFluid = "Gender Fluid"
    case genderNonconforming = "Gender non conforming"
    case genderVariant = "Gender Variant"
    case genderqueer = "Genderqueer"
    case intersex = "Intersex"
    case mtf = "Male to Female"
    case neither = "Neither"
    case trans = "Trans"
    case transMan = "Trans Man"
    case transWoman = "Trans Woman"
    case transMale = "Trans Male"
    case transFemale = "Trans Female"
    case transPerson = "Trans Person"
    case nonBinary = "Non-Binary"
    case pagender = "Pagender"
    case twoSpirit = "Two-spirit"
    case other = "Other"
}

extension MLookingFor {
    static let description = "Укажи свой гендер"
    
    static var modelStringAllCases: [String] {
        allCases.map { gender -> String in
             gender.rawValue
        }
    }
}



