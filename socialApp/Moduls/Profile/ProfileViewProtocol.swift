//
//  ProfileViewProtocol.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol ProfileViewProtocol: class {
    var collectionView: UICollectionView! { get set }
    
    func tapPremiumCell()
    func showPopUpMessage(header: String, text: String)
}
