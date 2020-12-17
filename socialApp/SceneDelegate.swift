//
//  SceneDelegate.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.06.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth
import ApphudSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var protectWindow: UIWindow?
    private var currentPeopleDelegate: CurrentPeopleDataDelegate?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
       // window?.windowScene = windowScene
        
        currentPeopleDelegate = CurrentPeopleDataProvider()
        AuthService.shared.checkAndSetRootViewController(currentPeopleDelegate: currentPeopleDelegate!) {[weak self] result in
            switch result {
            
            case .success(let rootVC):
                self?.window?.rootViewController = rootVC
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        
        window?.makeKeyAndVisible()
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaults.extensions.badge = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

//MARK: protectWindow
extension SceneDelegate {
    
}

extension SceneDelegate {
    
    private func makeRootVC(viewController: UIViewController, withNavContoller: Bool = false) -> UIViewController {
        
        if withNavContoller {
            let navVC = UINavigationController(rootViewController: viewController)
            navVC.navigationBar.isHidden = true
            navVC.navigationItem.backButtonTitle = "Войти с Apple ID"
            return navVC
        }
        return viewController
    }
    
    private func checkProfileInfo(userID: String, complition:@escaping(Result<(Bool,MPeople),Error>) -> Void){
        //show animate loadView
        PopUpService.shared.showAnimateView(name: MAnimamationName.loading.rawValue)
        
        FirestoreService.shared.getUserData(userID: userID) { result in
            switch result {
            
            case .success(let mPeople):
                //if don't have profile image, need setup profile
                if mPeople.userImage == "" {
                    complition(.success((false, mPeople)))
                } else {
                    complition(.success((true, mPeople)))
                }
                
            //error of getUserData
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

