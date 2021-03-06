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
    var apphudProducts: [ApphudProduct] = []
    
    private func refreshReceipt(){
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }
    
    public func setupPurchases(complition: @escaping(Bool) -> Void) {
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(self)
            complition(true)
        } else {
            complition(false)
        }
    }

    public func getProducts() {
        getProductsStoreKit()
    }
    
    private func getProductsStoreKit() {
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
        SKPaymentQueue.default().add(payment)
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
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
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func complitedPurchases(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(transaction.payment.productIdentifier), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    

    private func restoredPurchases(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(transaction.payment.productIdentifier), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
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
    func requestDidFinish(_ request: SKRequest) {
        //if finish update receipt, check subscribtion
        if request is SKReceiptRefreshRequest {
            if let currentPeople = UserDefaultsService.shared.getMpeople() {
                checkSubscribtion(currentPeople: currentPeople) { _ in }
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        if !products.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PurchasesService.productNotificationIdentifier), object: nil)
        }
    }
}

//MARK: validateReceipt
extension PurchasesService {
    public func validateReceipt(){
        
        #if DEBUG
                   let urlString = "https://sandbox.itunes.apple.com/verifyReceipt"
               #else
                   let urlString = "https://buy.itunes.apple.com/verifyReceipt"
               #endif
   
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptString = try? Data(contentsOf: receiptURL).base64EncodedString(),
              let url = URL(string: urlString) else {
            refreshReceipt()
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
