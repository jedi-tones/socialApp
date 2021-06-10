//
//  PeopleViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 05.07.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class PeopleViewController: UIViewController, UICollectionViewDelegate {
    
  //  private var currentPeople: MPeople?
    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    weak var peopleDelegate: PeopleListenerDelegate?
    weak var requestChatDelegate: RequestChatListenerDelegate?
    weak var likeDislikeDelegate: LikeDislikeListenerDelegate?
    weak var acceptChatDelegate: AcceptChatListenerDelegate?
    weak var reportDelegate: ReportsListnerDelegate?
    
    private var visibleIndexPath: IndexPath?
   
    private var emptyView = EmptyView(imageName: "empty",
                                      header: MLabels.emptyNearbyPeopleHeader.rawValue,
                                      text: MLabels.emptyNearbyPeopleText.rawValue,
                                      buttonText: MLabels.emptyNearbyPeopleButton.rawValue,
                                      delegate: self,
                                      selector: #selector(changeSearchTapped))
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SectionsPeople, MPeople>?

    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?,
         peopleDelegate: PeopleListenerDelegate?,
         requestChatDelegate: RequestChatListenerDelegate?,
         likeDislikeDelegate: LikeDislikeListenerDelegate?,
         acceptChatDelegate: AcceptChatListenerDelegate?,
         reportDelegate: ReportsListnerDelegate?) {
        
        self.currentPeopleDelegate = currentPeopleDelegate
        self.peopleDelegate = peopleDelegate
        self.requestChatDelegate = requestChatDelegate
        self.likeDislikeDelegate = likeDislikeDelegate
        self.acceptChatDelegate = acceptChatDelegate
        self.reportDelegate = reportDelegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupDiffebleDataSource()
        setupConstraints()
        setup()
        setupNotification()
        reloadData()
       // getPeople()
        
        DeeplinkManager.shared.checkDeeplink()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        setNeedsStatusBarAppearanceUpdate()
       
    }
    
    //MARK:  setup VC
    private func setup() {
        //check deeplink
        DeeplinkManager.shared.checkDeeplink()
        view.backgroundColor = .myWhiteColor()
        navigationItem.backButtonTitle = ""
    }
    
    private func setupNotification() {
        NotificationCenter.addObsorverToCurrentUser(observer: self, selector: #selector(updateCurrentPeople))
        NotificationCenter.addObsorverToPremiumUpdate(observer: self, selector: #selector(premiumIsUpdated))
        NotificationCenter.addObsorverToSearchSettingsNeedUpdate(observer: self, selector: #selector(changeSearchSettings))
    }
    
    //MARK: getPeople
    private func getPeople() {
        guard let likeDislikeDelegate = likeDislikeDelegate else { fatalError("Can't get likeDislikeDelegate")}
        guard let acceptChatDelegate = acceptChatDelegate else { fatalError("Can't get acceptChatDelegate")}
        guard let reportDelegate = reportDelegate else { fatalError("Can't get reportDelegate")}
        guard let currentPeople = currentPeopleDelegate else { fatalError("Can't get currentPeopleDelegate")}
        
        peopleDelegate?.getPeople(currentPeople: currentPeople.currentPeople,
                                  likeDislikeDelegate: likeDislikeDelegate,
                                  acceptChatsDelegate: acceptChatDelegate,
                                  reportsDelegate: reportDelegate,
                                  complition: { result in
                                    switch result {
                                    case .success(_):
                                        break
                                    case .failure(let error):
                                        fatalError(error.localizedDescription)
                                    }
                                  })
    }
    
    //MARK: setupCollectionView
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds,
                                          collectionViewLayout: setupCompositionLayout())
        collectionView.backgroundColor = .myWhiteColor()
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.isPagingEnabled = false
        collectionView.bounces = false
        
        let statusBarHieght = UIApplication.statusBarHeight
        collectionView.contentInset = UIEdgeInsets(top: -statusBarHieght, left: 0, bottom: 0, right: 0)
        collectionView.register(PeopleCell.self,
                                forCellWithReuseIdentifier: PeopleCell.reuseID)
        collectionView.register(SectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SectionHeader.reuseId)
    }
    
    //MARK: setupMainSection
    private func setupMainSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 1)
        
    
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        
//        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
//
//            self?.setUIForVisibleCells(items: visibleItems, point: point, enviroment: environment)
//            
//        }
        return section
    }
    
    //MARK: setupCompositionLayout
    private func setupCompositionLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            guard let section = SectionsPeople(rawValue: sectionIndex) else { fatalError("Unknown people section")}
            
            switch section {
            case .main:
                return self?.setupMainSection()
            }
        }
        return layout
    }

    //MARK: setupDataSource
    private func setupDiffebleDataSource() {
        dataSource = UICollectionViewDiffableDataSource<SectionsPeople,MPeople>(
            collectionView: collectionView,
            cellProvider: { [weak self] (collectionView, indexPath, people) -> UICollectionViewCell? in
                guard let section = SectionsPeople(rawValue: indexPath.section) else { fatalError("Unknown people section")}
                
                switch section {
                case .main:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PeopleCell.reuseID, for: indexPath) as? PeopleCell else { fatalError("Can't dequeue cell type PeopleCell")}
                    if let currentPeople = self?.currentPeopleDelegate?.currentPeople {
                        cell.configure(with: people, currentPeople: currentPeople, buttonDelegate: self)
                        {
                           // cell.setNeedsLayout()
                        }
                    }
                    return cell
                }
        })
    }
}

//MARK: setUIForVisivleCells
extension PeopleViewController {
    private func setUIForVisibleCells(items: [NSCollectionLayoutVisibleItem], point: CGPoint, enviroment: NSCollectionLayoutEnvironment) {
        
        items.forEach { visibleItem in
            let distanceFromCenter = abs((visibleItem.frame.midX - point.x) - enviroment.container.contentSize.width / 2.0)
           
            let minScale: CGFloat = 0.5
            let maxScale: CGFloat = 1
            let scale = max(maxScale - (distanceFromCenter / enviroment.container.contentSize.width / 2), minScale)
            visibleItem.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}

//MARK: objc
extension PeopleViewController {
    //MARK: updateCurrentPeople
    @objc private func updateCurrentPeople() {
        currentPeopleDelegate?.updatePeopleDataFromUserDefaults(complition: { result in
            switch result {
            
            case .success(_):
                break
            case .failure(let error):
                PopUpService.shared.showInfo(text: "Ошибка: \(error.localizedDescription)")
            }
        })
    }
    
    //MARK: premiumIsUpdated
    @objc private func premiumIsUpdated() {
        reloadData(reloadSection: true, animating: false)
    }
    
    @objc private func changeSearchSettings() {
        guard let likeDislikeDelegate = likeDislikeDelegate else { fatalError("likeDislikeDelegate is nil") }
        guard let acceptChatDelegate = acceptChatDelegate else { fatalError("acceptChatDelegate is nil") }
        guard let reportDelegate = reportDelegate else { fatalError("reportDelegate is nil") }
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil") }
        
        peopleDelegate?.getPeople(currentPeople: currentPeopleDelegate.currentPeople,
                                  likeDislikeDelegate: likeDislikeDelegate,
                                  acceptChatsDelegate: acceptChatDelegate,
                                  reportsDelegate: reportDelegate,
                                  complition: { _ in })
        
    }
    
    //MARK: checkPeopleNearbyIsEmpty
    private func checkPeopleNearbyIsEmpty()  {
        //if nearby people empty set
        guard let sortedPeopleNearby = peopleDelegate?.sortedPeopleNearby else { fatalError() }
        if sortedPeopleNearby.isEmpty {
            emptyView.hide(hidden: false)
        } else {
            emptyView.hide(hidden: true)
        }
        
    }
    
    //MARK: changeSearchTapped
    @objc private func changeSearchTapped() {
        
        let searchVC = EditSearchSettingsViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                        peopleListnerDelegate: peopleDelegate,
                                                        likeDislikeDelegate: likeDislikeDelegate,
                                                        acceptChatsDelegate: acceptChatDelegate,
                                                        reportsDelegate: reportDelegate)
        searchVC.hidesBottomBarWhenPushed = true
        searchVC.navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(searchVC, animated: true)
    }
}



//MARK: - PeopleCollectionViewDelegate
extension PeopleViewController: PeopleCollectionViewDelegate {
    
    
    //MARK:  updateData
    func updateData(item: MPeople, isDelete: Bool, reloadSection: Bool, animating: Bool = true, needScrollToItem: Bool, indexPathToScroll: IndexPath?) {
        
        guard var snapshot = dataSource?.snapshot() else { return }
        guard let sortedPeopleNearby = peopleDelegate?.sortedPeopleNearby else { fatalError() }
        
        if needScrollToItem {
            if let indexPathToScroll = indexPathToScroll, !sortedPeopleNearby.isEmpty {
                collectionView.scrollToItem(at: indexPathToScroll, at: .centeredHorizontally, animated: false)
            }
        }
        
        if isDelete {
            snapshot.deleteItems([item])
        } else {
            snapshot.appendItems([item], toSection: .main)
        }
        
        if reloadSection {
            snapshot.reloadSections([.main])
        }
        dataSource?.apply(snapshot, animatingDifferences: animating)
        
        checkPeopleNearbyIsEmpty()
    }
    
    
    //MARK:  reloadData
    func reloadData(reloadSection: Bool = false, animating: Bool = true, scrollToFirst:Bool = false) {
        guard let sortedPeopleNearby = peopleDelegate?.sortedPeopleNearby else { fatalError() }
        
        if scrollToFirst {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionsPeople,MPeople>()
        snapshot.appendSections([.main])
       
        snapshot.appendItems(sortedPeopleNearby, toSection: .main)
        
        if reloadSection {
            snapshot.reloadSections([.main])
            dataSource?.apply(snapshot, animatingDifferences: false)
        } else {
            dataSource?.apply(snapshot, animatingDifferences: animating)
        }
        
        checkPeopleNearbyIsEmpty()
    }
}

extension PeopleViewController {
    
    //MARK: checkLikeIsAvalible
    private func checkLikeIsAvalible(complition: @escaping() -> Void) {
        
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil") }
        
        FirestoreService.shared.addLikeCount(currentPeople: currentPeopleDelegate.currentPeople) {[weak self] result in
            switch result {
            
            case .success(_):
                complition()
            case .failure(let error):
                //if error of count likes
                if error as? UserError == UserError.freeCountOfLike {
                    PopUpService.shared.bottomPopUp(header: "На сегодня лайки закончились",
                                                    text: "Хочешь еще? Безлимитные лайки и многое другое с подпиской Flava Premium",
                                                    image: nil,
                                                    okButtonText: "Перейти на Flava premium") { [ weak self] in
                        
                        let purchasVC = PurchasesViewController(currentPeopleDelegate: self?.currentPeopleDelegate)
                        purchasVC.modalPresentationStyle = .fullScreen
                        self?.present(purchasVC, animated: true, completion: nil)
                    }
                } else {
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
    
    //MARK: saveLikeToFireStore
    private func saveLikeToFireStore(people: MPeople) {
        
        guard let reportDelegate = reportDelegate else { fatalError("reportDelegate is nil") }
        guard let peopleDelegate = peopleDelegate else { fatalError("peopleDelegate is nil") }
        guard let requestChatDelegate = requestChatDelegate else { fatalError("requestChatDelegate is nil") }
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil") }
        
        FirestoreService.shared.likePeople(currentPeople: currentPeopleDelegate.currentPeople,
                                           likePeople: people,
                                           requestChats: requestChatDelegate.requestChats) {[weak self] result, isMatch  in
            switch result {
            
            case .success(let likeChat):
                
                //add to local likePeople collection only when, current like is not match
                if !isMatch {
                    self?.likeDislikeDelegate?.likePeople.append(likeChat)
                }
                
                self?.peopleDelegate?.deletePeople(peopleID: likeChat.friendId)
                
                if isMatch {
                   
                    PopUpService.shared.showMatchPopUP(currentPeople: currentPeopleDelegate.currentPeople,
                                                       chat: likeChat) { messageDelegate, acceptChatDelegate in
                        let chatVC = ChatViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                        chat: likeChat,
                                                        messageDelegate: messageDelegate,
                                                        acceptChatDelegate: acceptChatDelegate,
                                                        reportDelegate: reportDelegate,
                                                        peopleDelegate: peopleDelegate,
                                                        requestDelegate: requestChatDelegate)
                        chatVC.hidesBottomBarWhenPushed = true
                        
                        self?.navigationController?.pushViewController(chatVC, animated: true)
                    }
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}
//MARK: - likeDislikeDelegate
extension PeopleViewController: PeopleButtonTappedDelegate {
    
    func timeTapped() {
        PopUpService.shared.bottomPopUp(header: "Хочешь видеть время последней активности пользователя?",
                                        text: "Последняя активность, безлимитные лайки и многое другое с подпиской Flava Premium",
                                        image: nil,
                                        okButtonText: "Перейти на Flava premium") { [weak self] in
            
            let purchasVC = PurchasesViewController(currentPeopleDelegate: self?.currentPeopleDelegate)
            purchasVC.modalPresentationStyle = .fullScreen
            self?.present(purchasVC, animated: true, completion: nil)
        }
    }
    
    func likePeople(people: MPeople) {
        //check like  is avalible
        checkLikeIsAvalible { [weak self] in
            self?.saveLikeToFireStore(people: people)
        }
    }
    
    func dislikePeople(people: MPeople) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil") }
        //save dislike to firestore
        FirestoreService.shared.dislikePeople(currentPeople: currentPeopleDelegate.currentPeople,
                                              dislikeForPeopleID: people.senderId,
                                              requestChats: requestChatDelegate?.requestChats ?? [],
                                              viewControllerDelegate: self) {[weak self] result in
            switch result {

            case .success((let dislikeChat, let isMissMatch)):
                //delete dislike people from array
                self?.peopleDelegate?.deletePeople(peopleID: people.senderId)
                //append to dislike array, for local changes
                self?.likeDislikeDelegate?.dislikePeople.append(dislikeChat)
                
                //if match is missed
                if isMissMatch {
                    //and currentUser don't have premium subscribtion
                    if !currentPeopleDelegate.currentPeople.isGoldMember && !currentPeopleDelegate.currentPeople.isTestUser {
                        //show notification
                        PopUpService.shared.showInfoWithButtonPopUp(header: "Ой, пропустили пару",
                                                                    text: "Подпишись на Flava premium, что бы не пропускать",
                                                                    cancelButtonText: "Позже",
                                                                    okButtonText: "Подписаться",
                                                                    font: .avenirBold(size: 16)) {
                            let purchasVC = PurchasesViewController(currentPeopleDelegate: currentPeopleDelegate)
                            purchasVC.modalPresentationStyle = .fullScreen
                            self?.present(purchasVC, animated: true, completion: nil)
                        }
                    }
                }

            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func reportTapped(people: MPeople) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil") }
        
        let reportVC = ReportViewController(currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                            reportUserID: people.senderId,
                                            isFriend: false,
                                            reportDelegate: reportDelegate,
                                            peopleDelegate: peopleDelegate,
                                            requestDelegate: requestChatDelegate)
        
        navigationController?.pushViewController(reportVC, animated: true)
    }
}

//MARK: setupConstraints
extension PeopleViewController {
    private func setupConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.translatesAutoresizingMaskIntoConstraints = false
       
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        
        NSLayoutConstraint.activate([
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
