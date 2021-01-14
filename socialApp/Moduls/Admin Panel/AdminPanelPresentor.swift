//
//  AdminPanelPresentor.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.01.2021.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation

class AdminPanelPresentor: AdminPanelPresentorProtocol {
    
    private weak var view: AdminPanelViewProtocol!
    private var router: RouterProfileProtocol!
    
    required init(view: AdminPanelViewProtocol, router: RouterProfileProtocol) {
        self.view = view
        self.router = router
    }
    
    func updateGeoHash() {
        FirestoreService.shared.updateGeoHashForAllUSer {[unowned self] result in
            switch result {
            
            case .success(let peoplesId):

                view.showInfoPopUp(header: "Update complite",
                                   text: "complite \(peoplesId.count) users")
            case .failure(let error):
                view.showInfoPopUp(header: "Error",
                                   text: error.localizedDescription)
            }
        }
    }
    
    func backupUsers() {
        FirestoreService.shared.backupAllusers {[unowned self] result in
            switch result {
            
            case .success(let peoplesId):
                view.showInfoPopUp(header: "Update complite",
                                   text: "complite \(peoplesId.count) users")
            case .failure(let error):
                view.showInfoPopUp(header: "Error",
                                   text: error.localizedDescription)
            }
        }
    }
    
    
}
