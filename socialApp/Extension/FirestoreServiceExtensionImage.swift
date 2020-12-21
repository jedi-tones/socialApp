//
//  FirestoreServiceImageExtension.swift
//  socialApp
//
//  Created by Денис Щиголев on 19.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import FirebaseAuth

//MARK: - WORK WITH IMAGE
extension FirestoreService {
    
    //MARK:  saveDefaultImage
    func saveDefaultImage(id: String, defaultImageString: String, complition: @escaping (Result<Void, Error>) -> Void) {
        usersReference.document(id).setData([MPeople.CodingKeys.userImage.rawValue : defaultImageString],
                                            merge: true,
                                            completion: { (error) in
                                                if let error = error {
                                                    complition(.failure(error))
                                                } else {
                                                    complition(.success(()))
                                                }
                                            })
    }
    
    //MARK: updateAvatarInChats
    
    func updateAvatarInChats(currentUserID: String,
                             avatarLink: String,
                             acceptChatsDelegate: AcceptChatListenerDelegate?,
                             likeDelegate: LikeDislikeListenerDelegate?) {
       
        let maxBatchDocumentCount = 500
        let acceptChatBatchStride = acceptChatsDelegate?.acceptChats.chunked(into: maxBatchDocumentCount)
        
        acceptChatBatchStride?.forEach({ acceptChats in
            let batch = db.batch()
            acceptChats.forEach({ chat in
                let friendAcceptChatRef = usersReference.document([chat.friendId,
                                                                   MFirestorCollection.acceptChats.rawValue,
                                                                   currentUserID].joined(separator: "/"))
                batch.setData([MChat.CodingKeys.friendUserImageString.rawValue : avatarLink],
                              forDocument: friendAcceptChatRef,
                              merge: true)
            })
            batch.commit()
        })
        
        let likeChatBatchStride = likeDelegate?.likePeople.chunked(into: maxBatchDocumentCount)
       
        likeChatBatchStride?.forEach({ likeChats in
            let batch = db.batch()
            likeChats.forEach({ chat in
                let friendAcceptChatRef = usersReference.document([chat.friendId,
                                                                   MFirestorCollection.requestsChats.rawValue,
                                                                   currentUserID].joined(separator: "/"))
                batch.setData([MChat.CodingKeys.friendUserImageString.rawValue : avatarLink],
                              forDocument: friendAcceptChatRef,
                              merge: true)
            })
            batch.commit()
        })
    }
    
    //MARK:  saveAvatar
    func saveAvatar(image: UIImage?, id: String, oldImageString: String? = nil, complition: @escaping (Result<String, Error>) -> Void) {
        
        guard let avatar = image else { return }
        
        //if have old image link, delete from storage
        if let oldImageString = oldImageString {
            StorageService.shared.deleteImage(link: oldImageString) { result in
                switch result {
                
                case .success(_):
                    break
                case .failure(let error):
                    PopUpService.shared.showInfo(text: error.localizedDescription)
                }
            }
        }
        
        //upload new photo to Storage
        StorageService.shared.uploadImage(image: avatar) {[weak self] result in
            switch result {
            
            case .success(let url):
                let userImageString = url.absoluteString
                //save user to FireStore
                self?.usersReference.document(id).setData([MPeople.CodingKeys.userImage.rawValue : userImageString,
                                                           MPeople.CodingKeys.lastActiveDate.rawValue : Date()],
                                                          merge: true,
                                                          completion: { error in
                                                            if let error = error {
                                                                complition(.failure(error))
                                                            } else {
                                                                //edit current user from UserDefaults for save request to server
                                                                if var people = UserDefaultsService.shared.getMpeople() {
                                                                    people.userImage = userImageString
                                                                    people.lastActiveDate = Date()
                                                                    UserDefaultsService.shared.saveMpeople(people: people)
                                                                    NotificationCenter.postCurrentUserNeedUpdate()
                                                                }
                                                                complition(.success(userImageString))
                                                            }
                                                          })
            case .failure(_):
                fatalError("Cant upload Image")
            }
        }
        
    }
    
    //MARK: updateAvatar
    func updateAvatar(galleryImage: MGallery, currentAvatarURL: String, id: String, complition:@escaping(Result<String, Error>) -> Void) {
        
        //set current image to profile image
        usersReference.document(id).setData(
            [MPeople.CodingKeys.userImage.rawValue : galleryImage.photo,
             MPeople.CodingKeys.lastActiveDate.rawValue : Date()],
            merge: true,
            completion: {[weak self] error in
                
                if let error = error {
                    complition(.failure(error))
                } else {
                    //edit current user from UserDefaults for save request to server
                    if var people = UserDefaultsService.shared.getMpeople() {
                        people.userImage = galleryImage.photo
                        people.lastActiveDate = Date()
                        UserDefaultsService.shared.saveMpeople(people: people)
                        NotificationCenter.postCurrentUserNeedUpdate()
                    }
                    //if success, delete current image from gallery, but save in storage, for use in profileImage
                    self?.deleteFromGallery(galleryImage: galleryImage, deleteInStorage: false, id: id) { result in
                        switch result {
                        
                        case .success(_):
                            //if delete is success, append old profile image to gallery
                            self?.saveImageToGallery(image: nil,
                                                     uploadedImageLink: currentAvatarURL,
                                                     id: id,
                                                     isPrivate: false,
                                                     index: galleryImage.property.index) { result in
                                switch result {
                                
                                case .success(_):
                                    complition(.success(galleryImage.photo))
                                case .failure(let error):
                                    complition(.failure(error))
                                }
                            }
                        case .failure(_):
                            break
                        }
                    }
                }
            }
        )
    }
    
    //MARK: makePhotoPrivate
    func makePhotoPrivate(currentUser: MPeople, galleryPhoto: MGallery, complition: @escaping (Result<MPeople,Error>)-> Void) {
        
        var privateStatus = galleryPhoto.property.isPrivate
        //switch status
        privateStatus.toggle()
        
        usersReference.document(currentUser.senderId).setData(
            [MPeople.CodingKeys.gallery.rawValue : [galleryPhoto.photo : [MGalleryPhotoProperty.CodingKeys.isPrivate.rawValue : privateStatus]]],
            merge: true) { error in
            if let error = error {
                complition(.failure(error))
            } else {
                if var people = UserDefaultsService.shared.getMpeople() {
                    people.gallery[galleryPhoto.photo] = MGalleryPhotoProperty(isPrivate: privateStatus,
                                                                               index: galleryPhoto.property.index)
                    UserDefaultsService.shared.saveMpeople(people: people)
                    NotificationCenter.postCurrentUserNeedUpdate()
                    complition(.success(people))
                } else {
                    complition(.failure(UserDefaultsError.cantGetData))
                }
            }
        }
    }
    
    //MARK:  saveImageToGallery
    func saveImageToGallery(image: UIImage?,
                            uploadedImageLink: String? = nil,
                            id: String,
                            isPrivate: Bool,
                            index: Int,
                            complition: @escaping (Result<String, Error>) -> Void) {
        
        //if new image, than upload to Storage
        if uploadedImageLink == nil {
            guard let image = image else { return }
            StorageService.shared.uploadImage(image: image) {[weak self] result in
                switch result {
                
                case .success(let url):
                    let userImageString = url.absoluteString
                    //save image to FireStore
                    self?.usersReference.document(id).setData(
                        [MPeople.CodingKeys.gallery.rawValue : [userImageString : [MGalleryPhotoProperty.CodingKeys.isPrivate.rawValue : isPrivate,
                                                                                   MGalleryPhotoProperty.CodingKeys.index.rawValue : index]],
                         MPeople.CodingKeys.lastActiveDate.rawValue : Date()],
                        merge: true,
                        completion: { error in
                            if let error = error {
                                complition(.failure(error))
                            } else {
                                //edit current user from UserDefaults for save request to server
                                if var people = UserDefaultsService.shared.getMpeople() {
                                    people.gallery[userImageString] = MGalleryPhotoProperty(isPrivate: isPrivate,
                                                                                            index: index)
                                    people.lastActiveDate = Date()
                                    UserDefaultsService.shared.saveMpeople(people: people)
                                    NotificationCenter.postCurrentUserNeedUpdate()
                                }
                                complition(.success(userImageString))
                            }
                        })
                case .failure(_):
                    fatalError("Cant upload Image")
                }
            }
        } else {
            //if image already upload, append link to gallery array
            guard let imageLink = uploadedImageLink else { return }
            usersReference.document(id).setData(
                [MPeople.CodingKeys.gallery.rawValue : [imageLink : [MGalleryPhotoProperty.CodingKeys.isPrivate.rawValue : isPrivate,
                                                                     MGalleryPhotoProperty.CodingKeys.index.rawValue : index]],
                 MPeople.CodingKeys.lastActiveDate.rawValue : Date()],
                merge: true,
                completion: { error in
                    if let error = error {
                        complition(.failure(error))
                    } else {
                        //edit current user from UserDefaults for save request to server
                        if var people = UserDefaultsService.shared.getMpeople() {
                            people.gallery[imageLink] = MGalleryPhotoProperty(isPrivate: isPrivate,
                                                                              index: index)
                            people.lastActiveDate = Date()
                            UserDefaultsService.shared.saveMpeople(people: people)
                            NotificationCenter.postCurrentUserNeedUpdate()
                        }
                        complition(.success(imageLink))
                    }
                })
        }
    }
    
    //MARK: deleteFromGallery
    func deleteFromGallery(galleryImage: MGallery, deleteInStorage:Bool = true,  id: String, complition:@escaping(Result<String, Error>) -> Void) {
        
        //delete image from array in Firestore
        usersReference.document(id).setData([MPeople.CodingKeys.gallery.rawValue : [galleryImage.photo : FieldValue.delete()],
                                             MPeople.CodingKeys.lastActiveDate.rawValue : Date()],
                                            merge: true,
                                            completion: { error in
                                                if let error = error {
                                                    complition(.failure(error))
                                                } else {
                                                    //edit current user from UserDefaults for save request to server
                                                    if var people = UserDefaultsService.shared.getMpeople() {
                                                        people.gallery[galleryImage.photo] = nil
                                                        people.lastActiveDate = Date()
                                                        UserDefaultsService.shared.saveMpeople(people: people)
                                                        NotificationCenter.postCurrentUserNeedUpdate()
                                                    }
                                                    if deleteInStorage {
                                                        //delete image from storage
                                                        StorageService.shared.deleteImage(link: galleryImage.photo) { result in
                                                            switch result {
                                                            
                                                            case .success(_):
                                                                complition(.success(galleryImage.photo))
                                                            case .failure(let error):
                                                                complition(.failure(error))
                                                            }
                                                        }
                                                    } else {
                                                        complition(.success(galleryImage.photo))
                                                    }
                                                }
                                            })
    }
}
