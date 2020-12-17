//
//  PeopleInfoViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class PeopleInfoViewController: UIViewController {
    
    private var peopleID: String
    private var people: MPeople?
    private var isFriend: Bool
    
    private let peopleView = PeopleView()
    private let loadingView = LoadingView(name: MAnimamationName.loading.rawValue, isHidden: false)
    
    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    weak var requestChatsDelegate: RequestChatListenerDelegate?
    weak var peopleDelegate: PeopleListenerDelegate?
    weak var reportDelegate: ReportsListnerDelegate?
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?,
         peopleID: String,
         isFriend: Bool,
         requestChatsDelegate: RequestChatListenerDelegate?,
         peopleDelegate: PeopleListenerDelegate?,
         reportDelegate: ReportsListnerDelegate?) {
        
        self.currentPeopleDelegate = currentPeopleDelegate
        self.peopleID = peopleID
        self.isFriend = isFriend
        self.requestChatsDelegate = requestChatsDelegate
        self.peopleDelegate = peopleDelegate
        self.reportDelegate = reportDelegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        configure()
        setupConstraints()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        peopleView.setNeedsLayout()
        
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setup() {
        view.backgroundColor = .myWhiteColor()
        peopleView.animateLikeButton.isHidden = isFriend
        peopleView.animateDislikeButton.isHidden = isFriend
    
      
        
    }
    
    func configure() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate in PeopleInfoVC is nil")}
        
        FirestoreService.shared.getUserData(userID: peopleID, complition: { [weak self] result in
            switch result {
            
            case .success(let mPeople):
                //calculate distance to this people
                let distance = LocationService.shared.getDistance(currentPeople: currentPeopleDelegate.currentPeople,
                                                                  newPeople: mPeople)
                var peopleWithDistanceInfo = mPeople
                peopleWithDistanceInfo.distance = distance
                self?.people = peopleWithDistanceInfo
                self?.peopleView.configure(with: peopleWithDistanceInfo,
                                           currentPeople: currentPeopleDelegate.currentPeople,
                                           showPrivatePhoto: true,
                                           buttonDelegate: self) {
                    self?.loadingView.hide()
                    
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        })
    }
}


extension PeopleInfoViewController: PeopleButtonTappedDelegate {
    
    func timeTapped() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate in PeopleInfoVC is nil")}
        
        PopUpService.shared.bottomPopUp(header: "Хочешь видеть время последней активности пользователя?",
                                        text: "Последняя активность, и многое другое с подпиской Flava Premium",
                                        image: nil,
                                        okButtonText: "Перейти на Flava premium") { [ weak self] in
            
            let purchasVC = PurchasesViewController(currentPeopleDelegate: currentPeopleDelegate)
            purchasVC.modalPresentationStyle = .fullScreen
            self?.present(purchasVC, animated: true, completion: nil)
        }
    }
    
     func likePeople(people: MPeople) {
        
        guard let requestChatsDelegate = requestChatsDelegate else { fatalError("Can't get requestChatsDelegate") }
        guard let peopleDelegate = peopleDelegate else {  fatalError("Can't get peopleDelegate")  }
        guard let reportDelegate = reportDelegate else {  fatalError("Can't get peopleDelegate")  }
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate in PeopleInfoVC is nil")}
        
        //save like to firestore
        FirestoreService.shared.likePeople(currentPeople: currentPeopleDelegate.currentPeople,
                                           likePeople: people,
                                           requestChats: requestChatsDelegate.requestChats ) {[weak self] result, isMatch in
            switch result {
            
            case .success(let likeChat):
                
                peopleDelegate.peopleNearby.removeAll { peopleDelegate -> Bool in
                    peopleDelegate.senderId == people.senderId
                }
                
                self?.peopleView.animateLikeButton.isHidden = true
                self?.peopleView.animateDislikeButton.isHidden = true
                
                requestChatsDelegate.reloadData(changeType: .delete)
                //for correct renew last people, need reload section
                peopleDelegate.reloadData(reloadSection: self?.peopleDelegate?.peopleNearby.count == 1 ? true : false,
                                          animating: false,
                                          scrollToFirst: false)
                
                if isMatch {
                    
                    PopUpService.shared.showMatchPopUP(currentPeople: currentPeopleDelegate.currentPeople,
                                                       chat: likeChat) { messageDelegate, acceptChatDelegate in
                        
                        let chatVC = ChatViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                        chat: likeChat,
                                                        messageDelegate: messageDelegate,
                                                        acceptChatDelegate: acceptChatDelegate,
                                                        reportDelegate: reportDelegate,
                                                        peopleDelegate: peopleDelegate,
                                                        requestDelegate: requestChatsDelegate)
                        
                        chatVC.hidesBottomBarWhenPushed = true
                        self?.navigationController?.pushViewController(chatVC, animated: true)
                    } cancelAction: {
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }
                
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
     }
    
     func dislikePeople(people: MPeople) {
        
        guard let requestChatsDelegate = requestChatsDelegate else { fatalError("Can't get requestChatsDelegate") }
        guard let peopleDelegate = peopleDelegate else {  fatalError("Can't get peopleDelegate")  }
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate in PeopleInfoVC is nil")}
        
        //save dislike from firestore
        FirestoreService.shared.dislikePeople(currentPeople: currentPeopleDelegate.currentPeople,
                                              dislikeForPeopleID: people.senderId,
                                              requestChats: requestChatsDelegate.requestChats,
                                              viewControllerDelegate: self) {[weak self] result in
            switch result {
            
            case .success(_):
                peopleDelegate.deletePeople(peopleID: people.senderId)
                
                self?.peopleView.animateLikeButton.isHidden = true
                self?.peopleView.animateDislikeButton.isHidden = true
                
                requestChatsDelegate.reloadData(changeType: .delete)
                
                self?.navigationController?.popToRootViewController(animated: true)
                
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func reportTapped(people: MPeople) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate in PeopleInfoVC is nil")}
        
        let reportVC = ReportViewController(currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                            reportUserID: people.senderId,
                                            isFriend: isFriend,
                                            reportDelegate: reportDelegate,
                                            peopleDelegate: peopleDelegate,
                                            requestDelegate: requestChatsDelegate)
        
        navigationController?.pushViewController(reportVC, animated: true)
    }
}

//MARK: setupConstraints
extension PeopleInfoViewController {
    private func setupConstraints() {
        
        view.addSubview(peopleView)
        view.addSubview(loadingView)
        
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        peopleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            peopleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            peopleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            peopleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            peopleView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}


