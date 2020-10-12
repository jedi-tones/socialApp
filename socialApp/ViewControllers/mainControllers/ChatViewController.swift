//
//  ChatsViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 25.09.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import MessageKit
import SDWebImage
import InputBarAccessoryView

class ChatViewController: MessagesViewController  {
    
    private let user:MPeople
    private let chat:MChat
    private var messages:[MMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        configure()
        configureInputBar()
        configureCameraBar()
        
        addMessageListener()
    }
    
    init(user:MPeople, chat:MChat) {
        self.user = user
        self.chat = chat
        
        super.init(nibName: nil, bundle: nil)
        title = chat.friendUserName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        ListenerService.shared.removeMessageListener()
    }
    
    //MARK: configure
    private func configure() {
        //delete avatar from message
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
        navigationController?.navigationBar.tintColor = .label
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    //MARK: addMessageListener
    private func addMessageListener() {
        ListenerService.shared.messageListener(chat: chat) {[weak self] result in
            switch result {
            
            case .success(let message):
                self?.newMessage(message: message)
                
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
    
    //MARK: newMessage
    private func newMessage(message: MMessage) {
        
        guard !messages.contains(message) else { return }
        messages.append(message)
        messages.sort { lhs, rhs -> Bool in
            lhs.sentDate < rhs.sentDate
        }
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToBottom(animated: false)
        }
    }
    
    //MARK: sendImage
    private func sendImage(image: UIImage) {
        StorageService.shared.uploadChatImage(image: image,
                                              chat: chat) { result in
            switch result {
            
            case .success(let url):
                var message = MMessage(user: self.user, image: image)
                message.imageURL = url
                FirestoreService.shared.sendMessage(chat: self.chat,
                                                    currentUser: self.user,
                                                    message: message) { result in
                    switch result {
                    
                    case .success():
                       break
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
    
    //MARK: configureInputBar
    private func configureInputBar() {
        messageInputBar.isTranslucent = false
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.middleContentView?.backgroundColor = .systemBackground
        
        messageInputBar.sendButton.setImage(#imageLiteral(resourceName: "sendMessage"), for: .normal)
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.setSize(CGSize(width: 36 , height: 36), animated: false)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.rightStackView.axis = .horizontal
        messageInputBar.inputTextView.placeholder = "Начни общение..."
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.inputTextView.backgroundColor = .systemBackground
        messageInputBar.middleContentViewPadding.right = -38
        messageInputBar.middleContentViewPadding.top = 20
    }
    
    //MARK: configureCameraBar
    private func configureCameraBar() {
        let cameraItem = InputBarButtonItem()
        cameraItem.image = #imageLiteral(resourceName: "imageSend")
        cameraItem.setSize(CGSize(width: 36, height: 36), animated: false)
        cameraItem.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        cameraItem.addTarget(self, action: #selector(tuppedSendImage), for: .primaryActionTriggered)
        
        
        messageInputBar.leftStackView.axis = .horizontal
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
      //  messageInputBar.leftStackView.
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
}

extension ChatViewController {
    //MARK: sendImage
    @objc private func tuppedSendImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        choosePhotoAlert {[ weak self ] sourceType in
            guard let sourceType = sourceType else { return }
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                picker.sourceType = sourceType
                self?.present(picker, animated: true, completion: nil)
            }
        }
    }
}

extension ChatViewController {
    //MARK: choosePhotoAlert
    private func choosePhotoAlert(complition: @escaping (_ sourceType:UIImagePickerController.SourceType?) -> Void) {
        
        let photoAlert = UIAlertController(title: nil,
                                           message: nil,
                                           preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Открыть камеру",
                                         style: .default) { _ in
                                            
                                            complition(UIImagePickerController.SourceType.camera)
        }
        let libraryAction = UIAlertAction(title: "Выбрать из галереи",
                                          style: .default) { _ in
                                            complition(UIImagePickerController.SourceType.photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Отмена",
                                         style: .default) { _ in
            complition(nil)
        }
        
        photoAlert.setMyStyle()
        photoAlert.addAction(cameraAction)
        photoAlert.addAction(libraryAction)
        photoAlert.addAction(cancelAction)
        
        present(photoAlert, animated: true, completion: nil)
    }
}

//MARK: pickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else { fatalError("Cant get image")}
        sendImage(image: image)
    }
}

extension ChatViewController: UINavigationControllerDelegate {
    
}
//MARK: MessagesDataSource
extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        user
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
}

//MARK: MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        CGSize(width: 0, height: 9)
    }
}

//MARK: MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .myMessageColor() : .friendMessageColor()
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .systemBackground : .label
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        .bubbleTail(isFromCurrentSender(message: message) ? MessageStyle.TailCorner.bottomRight : MessageStyle.TailCorner.bottomLeft, MessageStyle.TailStyle.pointedEdge)
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        switch message.kind {
        case .photo(let photoItem):
            if let url = photoItem.url {
                imageView.sd_setImage(with: url)
            }
        default:
            break
        }
    }
}

//MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = MMessage(user: user, content: text)
        
        FirestoreService.shared.sendMessage(chat: chat,
                                            currentUser: user,
                                            message: message) { result in
            switch result {
            
            case .success():
                break
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        inputBar.inputTextView.text = ""
        
    }
}