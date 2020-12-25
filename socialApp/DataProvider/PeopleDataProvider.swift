//
//  PeopleDataProvider.swift
//  socialApp
//
//  Created by Денис Щиголев on 29.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import Foundation

class PeopleDataProvider: PeopleListenerDelegate {
    
    private var userID: String
    private var lastPeople: MPeople?
    weak var peopleCollectionViewDelegate: PeopleCollectionViewDelegate?
    
    var peopleNearby: [MPeople] = [] {
        didSet {
            sortedPeopleNearby = peopleNearby.sorted { p1, p2  in
                p1.distance < p2.distance
            }
            lastPeople = sortedPeopleNearby.last
        }
    }
    var sortedPeopleNearby: [MPeople] = [] {
        didSet {
            checkAndLoadMorePeople()
        }
    }
    
    
    
    init(userID: String) {
        self.userID = userID
        setup()
    }
    
    private func setup() {
        NotificationCenter.addObsorverCoordinatesIsUpdate(observer: self, selector: #selector(updateDistanceToPeople))
    }
    
    @objc private func updateDistanceToPeople() {
        print("\n distance is updated \n")
    }
    
    //MARK: work with collectionView
    func updateData(item: MPeople, isDelete: Bool, reloadSection: Bool, animating: Bool, needScrollToItem: Bool, indexPathToScroll: IndexPath?) {
        peopleCollectionViewDelegate?.updateData(item: item,
                                                 isDelete: isDelete,
                                                 reloadSection: reloadSection,
                                                 animating: animating,
                                                 needScrollToItem: needScrollToItem,
                                                 indexPathToScroll: indexPathToScroll)
    }
    
    func reloadData(reloadSection: Bool, animating: Bool, scrollToFirst: Bool) {
        peopleCollectionViewDelegate?.reloadData(reloadSection: reloadSection, animating: animating, scrollToFirst: scrollToFirst)
    }
}

extension PeopleDataProvider {
    
    private func checkAndLoadMorePeople() {
        if sortedPeopleNearby.count <= 2 {
           
            
        }
    }
    
    //MARK:  get requestChats
    func getPeople(currentPeople: MPeople,
                   likeDislikeDelegate: LikeDislikeListenerDelegate,
                   acceptChatsDelegate: AcceptChatListenerDelegate,
                   reportsDelegate: ReportsListnerDelegate,
                   complition: @escaping (Result<[MPeople], Error>) -> Void) {
        
        FirestoreService.shared.getPeoplePaginate(currentPeople: currentPeople,
                                                  likeChat: likeDislikeDelegate.likePeople,
                                                  dislikeChat: likeDislikeDelegate.dislikePeople,
                                                  acceptChat: acceptChatsDelegate.acceptChats,
                                                  reports: reportsDelegate.reports) {[weak self] result in
            switch result {
            
            case .success(let peoples):
                self?.peopleNearby = peoples
                let scrollToFirst = peoples.isEmpty ? false : true
                //let scrollToFirst = false
                self?.reloadData(reloadSection: peoples.count == 1 ? true : false, animating: true, scrollToFirst: scrollToFirst)
                print("\n reload")
                complition(.success(peoples))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
    
    //delete people
    func deletePeople(peopleID: String) {
      
        let peopleIndex = sortedPeopleNearby.firstIndex { mPeople -> Bool in
            mPeople.senderId == peopleID
        }
        guard let index = peopleIndex else { return }
        let peopleToRemove = sortedPeopleNearby[index]
       
        //need scroll only count collection > 1 and if elemt last in collection
        let needScroll = (index != sortedPeopleNearby.count - 1) || sortedPeopleNearby.count == 1 ? false : true
        
        let indexPathToScroll = needScroll ? IndexPath(item: index - 1, section: 0) : nil
        
        sortedPeopleNearby.remove(at: index)
        updateData(item: peopleToRemove,
                   isDelete: true,
                   reloadSection: sortedPeopleNearby.count == 1 ? true : false,
                   animating: true,
                   needScrollToItem: needScroll,
                   indexPathToScroll: indexPathToScroll)
    }
}

