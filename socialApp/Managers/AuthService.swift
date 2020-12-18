//
//  AuthService.swift
//  socialApp
//
//  Created by Денис Щиголев on 01.09.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import ApphudSDK

class AuthService {
    
    static let shared = AuthService()
    private let auth = Auth.auth()
    var currentNonce: String?  //hashed nonce string
    
    private init() {}
    
    private func makeRootVC(viewController: UIViewController, withNavContoller: Bool = false) -> UIViewController {
        
        if withNavContoller {
            let navVC = UINavigationController(rootViewController: viewController)
            navVC.navigationBar.isHidden = true
            navVC.navigationItem.backButtonTitle = "Войти с Apple ID"
            return navVC
        }
        return viewController
    }
    
    private func checkProfileInfo(currentPeopleDelegate: CurrentPeopleDataDelegate?,
                                  userID: String,
                                  complition:@escaping(Result<Bool,Error>) -> Void){
        //show animate loadView
        PopUpService.shared.showAnimateView(name: MAnimamationName.loading.rawValue)
        
        currentPeopleDelegate?.updatePeopleDataFromFirestore(userID: userID,
                                                             complition: { result in
            switch result {
            
            case .success(let mPeople):
                //if don't have profile image, need setup profile
                if mPeople.userImage == "" {
                    complition(.success(false))
                } else {
                    complition(.success(true))
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        })
    }
    
    //MARK: checkAndSetRootViewController
    func checkAndSetRootViewController(currentPeopleDelegate: CurrentPeopleDataDelegate,
                                       complition:@escaping(Result<UIViewController,Error>)-> Void ) {
        if let user = Auth.auth().currentUser {
            //try reload, to check profile is avalible on server
            user.reload {[unowned self] error in
                if let _ = error {
                    //if profile don't avalible, log out
                    signOut(currentPeopleDelegate: currentPeopleDelegate) { result in
                        switch result {
                        case .success(_):
                            Apphud.logout()
                            currentPeopleDelegate.deletePeople()
                            let rootViewController = makeRootVC(viewController: AuthViewController(currentPeopleDelegate: currentPeopleDelegate),
                                                                withNavContoller: true)
                            complition(.success(rootViewController))
                            
                            
                        case .failure(let error):
                            fatalError(error.localizedDescription)
                        }
                    }
                } else {
                    if let userID = user.email {
                        //if user avalible, check correct setup user info
                        checkProfileInfo(currentPeopleDelegate: currentPeopleDelegate,
                                         userID: userID) { result in
                            switch result {
                            
                            case .success(let isCompliteSetup):
                                //if user have profile photo, than go main vc
                                if isCompliteSetup {
                                    let rootViewController = makeRootVC(viewController: MainTabBarController(currentPeopleDelegate: currentPeopleDelegate,
                                                                                                             isNewLogin: false),
                                                                        withNavContoller: false)
                                    complition(.success(rootViewController))
                                    
                                } else {
                                    //stop load animation animation
                                    PopUpService.shared.dismisPopUp(name: MAnimamationName.loading.rawValue) {}
                                    // if don't have user photo (last step of first setup profile), go setup
                                    let navController = UINavigationController(rootViewController: DateOfBirthViewController(currentPeopleDelegate: currentPeopleDelegate))
                                    navController.navigationBar.tintColor = .label
                                    navController.navigationBar.shadowImage = UIImage()
                                    navController.navigationBar.barTintColor = .myWhiteColor()
                                    complition(.success(navController))
                                    
                                    PopUpService.shared.showInfo(text: "Необходимо закончить заполнение профиля")
                                }
                            case .failure(_):
                                //stop load animation animation
                                PopUpService.shared.dismisPopUp(name: MAnimamationName.loading.rawValue) {}
                                PopUpService.shared.bottomPopUp(header: "Проблема с учетной записью",
                                                                text: "Не удалось получить информацию для входа",
                                                                image: nil,
                                                                okButtonText: "Попробовать еще") {
                                    //make root Auth vc
                                    let rootVC = makeRootVC(viewController: AuthViewController(currentPeopleDelegate: currentPeopleDelegate),
                                                            withNavContoller: true)
                                    complition(.success(rootVC))
                                }
                            }
                        }
                    }
                }
            }
        } else {
           //if don't have avalible current auth in firebase, set root authVc
            let rootVC = makeRootVC(viewController: AuthViewController(currentPeopleDelegate: currentPeopleDelegate),
                                    withNavContoller: true)
            complition(.success(rootVC))
        }
    }
    
    //MARK: isEmailAlreadyRegister
    func isEmailAlreadyRegister(email: String?, complition: @escaping(Result<Bool,Error>) -> Void) {
        guard let email = email else { return }
        
        auth.fetchSignInMethods(forEmail: email) { (methods, error) in
            if let error = error {
                complition(.failure(error))
            } else if methods != nil {
                complition(.success(true))
            } else {
                complition(.success(false))
            }
        }
    }
    
    //MARK: verifyEmail
    func verifyEmail(user: User, complition: @escaping(Result<Bool,Error>) -> Void) {
        
        user.sendEmailVerification { error in
            
            //need complite verification method
        }
    }
    
    //MARK: - sendAppleIdRequest
    //send appleIdRequset to signIn
    func AppleIDRequest(delegateController: ASAuthorizationControllerDelegate,
                        presetationController: ASAuthorizationControllerPresentationContextProviding) {
        let request = createAplleIDRequest()
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        authController.delegate = delegateController
        authController.presentationContextProvider = presetationController
        
        authController.performRequests()
    }
    
    //MARK: - getCredentialApple
    //after complite auth get token and push to FirebaseAuth
    func didCompleteWithAuthorizationApple(authorization: ASAuthorization,
                                           complition: @escaping (Result<OAuthCredential,Error>) -> Void) {
        
        if let authCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let nonce = currentNonce else { fatalError("No login request was sent")}
            
            guard let appleIDToken = authCredential.identityToken else {
                complition(.failure(AuthError.appleToken))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                complition(.failure(AuthError.serializeAppleToken))
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            complition(.success(credential))
        }
    }
    
    //MARK: - signInApple
    func signInApple(with credential: OAuthCredential, complition: @escaping (Result<User, Error>) -> Void) {
        
        auth.signIn(with: credential) { data, error in
            if let user = data?.user {
                complition(.success(user))
            } else if let error = error {
                complition(.failure(error))
            }
        }
    }
    
    
    //MARK: - register mail
    func register(email: String?,
                  password: String?,
                  confirmPassword: String?,
                  complition: @escaping (Result<User, Error>) -> Void ) {
        
        let isFilledCheck = Validators.shared.isFilledRegister(email: email,
                                                               password: password,
                                                               confirmPassword: confirmPassword)
        
        guard isFilledCheck.isFilled else { complition(.failure(AuthError.notFilled))
            return }
        
        
        guard Validators.shared.isConfirmPassword(password1: isFilledCheck.password, password2: isFilledCheck.confirmPassword) else {
            complition(.failure(AuthError.passwordNotMatch))
            return
        }
        
        
        auth.createUser(withEmail: isFilledCheck.email, password: isFilledCheck.password) { result, error in
            
            guard let result = result else {
                complition(.failure(error!))
                return
            }
            complition(.success(result.user))
        }
    }
    
    //MARK: - signIn mail
    func signIn(email: String?,
                password: String?,
                complition: @escaping (Result<User,Error>) -> Void) {
        
        let isFilledCheck = Validators.shared.isFilledSignIn(email: email, password: password)
        
        guard isFilledCheck.isFilled else { complition(.failure(AuthError.notFilled))
            return
        }
        
        auth.signIn(withEmail: isFilledCheck.email, password: isFilledCheck.password) { result, error in
            
            guard let result = result else {
                complition(.failure(error!))
                return
            }
            
            complition(.success(result.user))
            
        }
    }
    
    //MARK: - signOut
    func signOut(currentPeopleDelegate: CurrentPeopleDataDelegate?, complition: @escaping (Result<Bool,Error>)-> Void) {
        do {
            try Auth.auth().signOut()
            
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            keyWindow?.rootViewController = AuthViewController(currentPeopleDelegate: currentPeopleDelegate)
            
            complition(.success(true))
        } catch {
            complition(.failure(error))
        }
    }
    
    //MARK: - reAuthentificate
    func reAuthentificate(credential: AuthCredential?, email: String?, password: String?, complition: @escaping (Result<User,Error>) -> Void) {
        let user = Auth.auth().currentUser

        if let newCredential = credential {
            user?.reauthenticate(with: newCredential) { arg, error   in
                if let error = error {
                    complition(.failure(error))
                } else {
                    if let user = arg?.user {
                        complition(.success(user))
                    }
                }
            }
        } else {
            //if dont have credential, login with email to get them
            guard let email = email else { complition(.failure(AuthError.invalidEmail)); return }
            guard let password = password else { complition(.failure(AuthError.invalidPassword)); return }
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    complition(.failure(error))
                }
                if let result = result {
                    complition(.success(result.user))
                }
            }
        }
    }
    
    //MARK: - deleteUser
    func deleteUser(complition: @escaping (Result<Bool,Error>)-> Void) {
        auth.currentUser?.delete(completion: { error in
            if let error = error {
                complition(.failure(error))
            } else {
                complition(.success(true))
            }
        })
    }
}

//MARK: -  appleIDRequest
extension AuthService {
    
    private func createAplleIDRequest() ->ASAuthorizationAppleIDRequest {
        
        let appleIDAuthProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDAuthProvider.createRequest()
        request.requestedScopes = [.fullName, .email ]
        
        let nonce = CryptoService.shared.randomNonceString()
        request.nonce = CryptoService.shared.sha256(nonce)
        currentNonce = nonce
        
        return request
    }
}

extension AuthService {
    
   
}
