//
//  PurchasesService.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation
import StoreKit
import ApphudSDK

class PurchasesService: NSObject {
    
    static let shared = PurchasesService()
    static let productNotificationIdentifier = "PurchasesServiceProductIdentifier"
    private override init() { }
    
    var products: [SKProduct] = []
    let paymentQueue = SKPaymentQueue.default()
    private var timerToUpdateSubscribtion: Timer?
    
    public func setupPurchases(complition: @escaping(Bool) -> Void) {
        if SKPaymentQueue.canMakePayments() {
            paymentQueue.add(self)
            complition(true)
        } else {
            complition(false)
        }
    }
    
    public func getProducts() {
        let identifieres: Set = [
            MPurchases.sevenDays.rawValue,
            MPurchases.oneMonth.rawValue,
            MPurchases.threeMonth.rawValue,
            MPurchases.oneYear.rawValue,
        ]
        
        let productRequest = SKProductsRequest(productIdentifiers: identifieres)
        productRequest.delegate = self
        productRequest.start()
    }
    
    public func purches(product identifier: MPurchases) {
        guard let product = products.filter({$0.productIdentifier == identifier.rawValue}).first else { return }
        let payment = SKPayment(product: product)
        paymentQueue.add(payment)
    }
    
    public func restorePurchases() {
        paymentQueue.restoreCompletedTransactions()
    }

    
    public func checkSubscribtion(currentPeople: MPeople, complition: @escaping (Result<(),Error>) -> Void) {
        restorePurchasesWithApphud { result in
            switch result {
            
            case .success(_):
                var isGoldMember = false
                var goldMemberDate:Date?
                var goldMemberPurches:MPurchases?
                
                if Apphud.hasActiveSubscription() {
                    if let subscribtion = Apphud.subscription() {
                        isGoldMember = true
                        goldMemberDate = subscribtion.expiresDate
                        goldMemberPurches = MPurchases(rawValue: subscribtion.productId)
                    }
                }
                
                //if status don't change, go to complition
                guard currentPeople.isGoldMember != isGoldMember,
                      currentPeople.goldMemberDate != goldMemberDate,
                      currentPeople.goldMemberPurches != goldMemberPurches else {
                    complition(.success(()))
                    return
                }
                
                //if satus change, save to firestore
                FirestoreService.shared.saveIsGoldMember(id: currentPeople.senderId,
                                                         isGoldMember: isGoldMember,
                                                         goldMemberDate: goldMemberDate,
                                                         goldMemberPurches: goldMemberPurches) {[weak self] result in
                    switch result {
                    
                    case .success(_):
                        
                        //setup timer to update subscribtion on goldMemberDate
                        if isGoldMember {
                            if let timerToUpdateSubscribtion = self?.timerToUpdateSubscribtion {
                                timerToUpdateSubscribtion.invalidate()
                            }
                            if let goldMemberDate = goldMemberDate {
                                let timeIntervalToFire = goldMemberDate.timeIntervalSinceNow
                                self?.timerToUpdateSubscribtion = Timer.scheduledTimer(withTimeInterval: timeIntervalToFire,
                                                                                       repeats: false,
                                                                                       block: { timer in
                                                                                        self?.checkSubscribtion(currentPeople: currentPeople, complition: { _ in })
                                                                                       })
                                self?.timerToUpdateSubscribtion?.tolerance = 10
                            }
                        }
                        complition(.success(()))
                        
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
    
    public func validateReceipt(){
        
        #if DEBUG
                   let urlString = "https://sandbox.itunes.apple.com/verifyReceipt"
               #else
                   let urlString = "https://buy.itunes.apple.com/verifyReceipt"
               #endif

        guard let receiptURL = Bundle.main.appStoreReceiptURL, let receiptString = try? Data(contentsOf: receiptURL).base64EncodedString() , let url = URL(string: urlString) else {
                return
        }

        let requestData : [String : Any] = ["receipt-data" : receiptString,
                                            "password" : "d41125c476f14b5c8d9bbfd18e47e93d",
                                            "exclude-old-transactions" : false]
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        URLSession.shared.dataTask(with: request)  { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
                // your non-consumable and non-renewing subscription receipts are in `in_app` array
                // your auto-renewable subscription receipts are in `latest_receipt_info` array
                    
                    guard
                        let appStoreReceipt = jsonData as? [String : Any],
                        let _ = appStoreReceipt["latest_receipt_info"] as? [[String:Any]]
                    else {
                        return
                    }
              }
            }
        }.resume()
    }
}

//MARK: purchases with apphud
extension PurchasesService {
    
    public func purcheWithApphud(product identifier: MPurchases, complition: @escaping (Result<ApphudPurchaseResult, Error>) -> Void) {
        guard let product = products.filter({$0.productIdentifier == identifier.rawValue}).first else { return }
        Apphud.purchase(product) { result in
            complition(.success(result))
        }
    }
    
    public func restorePurchasesWithApphud(complition: @escaping(Result<[ApphudSubscription], Error>)-> Void) {
        Apphud.restorePurchases { (subscristions, nonRenewPurches, error) in
            if let error = error {
                complition(.failure(error))
            } else if let subscristions = subscristions {
                complition(.success(subscristions))
            }
        }
    }
    
    public func checkActiveSubscribtionWithApphud() -> Bool {
        Apphud.hasActiveSubscription()
    }
    
}


//MARK: paymentQueue func
extension PurchasesService {
    private func failedPurchases(transaction: SKPaymentTransaction) {
        if let paymentError = transaction.error as NSError? {
            if paymentError.code != SKError.paymentCancelled.rawValue {
                PopUpService.shared.bottomPopUp(header: "Ошибка транзации",
                                                text: paymentError.localizedDescription,
                                                image: nil,
                                                okButtonText: "Поробую еще раз",
                                                okAction: {} )
            }
        }
        paymentQueue.finishTransaction(transaction)
    }
    
    private func complitedPurchases(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(transaction.payment.productIdentifier), object: nil)
        paymentQueue.finishTransaction(transaction)
    }
    
    private func restoredPurchases(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(transaction.payment.productIdentifier), object: nil)
        paymentQueue.finishTransaction(transaction)
    }
}

//MARK: SKPaymentTransactionObserver
extension PurchasesService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
       /* current use Apphud queue functioal
         
        for transaction in transactions {
            switch transaction.transactionState {
            
            case .purchasing:
                break
            case .purchased:
                break
                // complitedPurchases(transaction: transaction)
            case .failed:
                break
                // failedPurchases(transaction: transaction)
            case .restored:
                break
                // restoredPurchases(transaction: transaction)
            case .deferred:
                break
            @unknown default:
                break
            }
        }
         */
    }
}

//MARK: SKProductsRequestDelegate
extension PurchasesService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        products = response.products
        if !products.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PurchasesService.productNotificationIdentifier), object: nil)
        }
    }
}
