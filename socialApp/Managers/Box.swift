//
//  Box.swift
//  socialApp
//
//  Created by Денис Щиголев on 08.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class Box<T> {
    
    typealias Listner = (T) -> Void
    
    var listner: Listner?
    
    var value:T {
        didSet {
            listner?(value)
        }
    }
    
    init(value:T) {
        self.value = value
    }
    
    func bind(listner: @escaping Listner) {
        self.listner = listner
        self.listner?(value)
    }
}
