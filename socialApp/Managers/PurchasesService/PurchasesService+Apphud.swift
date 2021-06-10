//
//  PurchasesService+Apphud.swift
//  socialApp
//
//  Created by Денис Щиголев on 6/10/21.
//  Copyright © 2021 Денис Щиголев. All rights reserved.
//

import Foundation
import StoreKit
import ApphudSDK

extension PurchasesService {
    func apphudStart() {
        Apphud.start(apiKey: "app_LDXecjNbEuvUBtpd3J9kw75A6cH14n")
    }
    
    func apphudUpdateUserID(id: String) {
        Apphud.updateUserID(id)
    }
    
    func apphudLogout() {
        Apphud.logout()
    }
    
    func getProductsFromApphud() {
        print("[\(type(of: self))]", #function)
        Apphud.getPaywalls {[weak self] apphudPaywall, error in
            guard let self = self,
                  error == nil
            else { return }
            print("[\(type(of: self))]", #function, " My log apphudPaywall \(String(describing: apphudPaywall))")
            if let products = apphudPaywall?.first?.products {
                self.apphudProducts = products
            }
        }
    }
    
    public func purcheWithApphud(product identifier: MPurchases, complition: @escaping (Result<ApphudPurchaseResult, Error>) -> Void) {
        guard let apphudProduct = apphudProducts.first(where: {$0.productId == identifier.rawValue})
        else {
            complition(.failure(PurchasesError.unknownProduct))
            return
        }
        Apphud.purchase(apphudProduct) { apphudPurchaseResult in
            complition(.success(apphudPurchaseResult))
        }
    }
    
    public func restorePurchasesWithApphud(complition: @escaping(Result<(), Error>)-> Void) {
        Apphud.restorePurchases { (subscristions, nonRenewPurches, error) in
            if let error = error {
                complition(.failure(error))
            } else {
                complition(.success(()))
            }
        }
    }
    
    public func checkActiveSubscribtionWithApphud() -> Bool {
        Apphud.hasActiveSubscription()
    }
    
    //MARK: check subscribtion
    public func checkSubscribtion(currentPeople: MPeople, isRestore:Bool = false, complition: @escaping (Result<MPeople,Error>) -> Void) {
        restorePurchasesWithApphud { result in
            switch result {
            
            case .success(_):
                var isGoldMember = false
                var goldMemberDate:Date?
                var goldMemberPurches:MPurchases?
                
                if Apphud.hasActiveSubscription() {
                    isGoldMember = true
                    if let subscribtion = Apphud.subscription() {
                        goldMemberDate = subscribtion.expiresDate
                        goldMemberPurches = MPurchases(rawValue: subscribtion.productId)
                    }
                } else if isRestore {
                    PopUpService.shared.showInfo(text: "Активные подписки не найдены")
                }
                
                //if status don't change, go to complition
                guard currentPeople.isGoldMember != isGoldMember ||
                      currentPeople.goldMemberDate != goldMemberDate ||
                      currentPeople.goldMemberPurches != goldMemberPurches else {
                    complition(.success((currentPeople)))
                    return
                }
                
                //if is not premium user, change premium settings to defaults
                if !isGoldMember && !currentPeople.isTestUser {
                    print("\n CHANGE TO DEFAULT")
                    FirestoreService.shared.setDefaultPremiumSettings(currentPeople: currentPeople) { _ in }
                }
                
                //if satus change, save to firestore
                FirestoreService.shared.saveIsGoldMember(id: currentPeople.senderId,
                                                         isGoldMember: isGoldMember,
                                                         goldMemberDate: goldMemberDate,
                                                         goldMemberPurches: goldMemberPurches) { result in
                    switch result {
                    
                    case .success(let updatedPeople):
                        //if is restore, show popUp
                        complition(.success(updatedPeople))
                        
                        if isRestore, isGoldMember {
                            PopUpService.shared.showInfo(text: "Flava premium восстановлен")
                        }
                        
                    case .failure(let error):
                        complition(.failure(error))
                    }
                }
                
            case .failure(let error):
                PopUpService.shared.showInfo(text: "Не удалось проверить подписку")
                complition(.failure(error))
            }
        }
    }
}
