//
//  RouterMain.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import UIKit

protocol RouterMain {
    var navigationController: UINavigationController? { get set }
    var moduleBuilder: BuilderProtocol? { get set }
}
