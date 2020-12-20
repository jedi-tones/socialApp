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

class ChatViewController: MessagesViewController, MessageControllerDelegate  {
    
    var chat:MChat {
        didSet {
            chatIsChanged()
        }
    }
    var lastMessage: MMessage? {
        didSet {
            acceptChatDelegate?.lastMessageInSelectedChat = lastMessage
        }
    }
    
    private let loadingMessagesImage = AnimationCustomView(name: MAnimamationName.loading.rawValue,
                                                   loopMode: .loop,
                                                   contentMode: .scaleAspectFit,
                                                   isHidden: false)
    private lazy var titleView = ChatTitleStackView(chat: chat,
                                                    target: self,
                                                    profileTappedAction: #selector(profileTapped))
    weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    weak var acceptChatDelegate: AcceptChatListenerDelegate?
    weak var messageDelegate: MessageListenerDelegate?
    weak var reportDelegate: ReportsListnerDelegate?
    weak var peopleDelegate: PeopleListenerDelegate?
    weak var requestDelegate: RequestChatListenerDelegate?
    
    lazy var isInitiateDeleteChat = false
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?,
         chat: MChat,
         messageDelegate: MessageListenerDelegate?,
         acceptChatDelegate: AcceptChatListenerDelegate?,
         reportDelegate: ReportsListnerDelegate?,
         peopleDelegate: PeopleListenerDelegate?,
         requestDelegate: RequestChatListenerDelegate?) {
        
        self.currentPeopleDelegate = currentPeopleDelegate
        self.chat = chat
        self.messageDelegate = messageDelegate
        self.acceptChatDelegate = acceptChatDelegate
        self.reportDelegate = reportDelegate
        self.peopleDelegate = peopleDelegate
        self.requestDelegate = requestDelegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeMessageListner()
        removeListners()
        acceptChatDelegate?.messageCollectionViewDelegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureInputBar()
        configureCameraBar()
        setupConstraints()
        
        getAllMessages()
        addListners()
        showTimerPopUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if parent == nil {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    //MARK: addMessageListener
    private func addMessageListener() {
        messageDelegate?.setupListener(chat: chat)
    }
    
    private func removeMessageListner() {
        messageDelegate?.removeListener()
    }
    
    func chatsCollectionWasUpdate(chat: MChat) {
        if chat.friendId == self.chat.friendId {
            self.chat = chat
        }
    }
    
    //MARK: configure
    private func configure() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        messageDelegate?.messageControllerDelegate = self
        
        acceptChatDelegate?.messageCollectionViewDelegate = self
        
        showMessageTimestampOnSwipeLeft = true
    
        messagesCollectionView.backgroundColor = .myWhiteColor()
        //delete avatar from message
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
        
        navigationItem.titleView = titleView
        navigationItem.backButtonTitle = ""
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                            style: .done,
                                            target: self,
                                            action: #selector(chatSettingsTapped))
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    
    private func addListners() {
        //add screenshot observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenshotTaken),
                                               name: UIApplication.userDidTakeScreenshotNotification,
                                               object: nil)
        ScreenRecordingManager.shared.setupListner {[weak self] isCaptured in
            if isCaptured {
                self?.screenIsCaptured()
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidChanged),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeListners() {
        NotificationCenter.default.removeObserver(self)
        ScreenRecordingManager.shared.removeListner()
    }
    
    //MARK: chatIsChanged
    private func chatIsChanged() {
        titleView.changePeopleStatus(isOnline: chat.friendInChat)
        messagesCollectionView.reloadData()
    }
    
    //MARK: getAllMessages
    private func getAllMessages() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        loadingMessagesImage.play()
        messageDelegate?.getAllMessages(currentUserId: currentPeopleDelegate.currentPeople.senderId,
                                        chat: chat,
                                        complition: {[weak self] result in
                                            switch result {
                                            
                                            case .success(_):
                                                self?.messagesCollectionView.reloadData()
                                                self?.messagesCollectionView.scrollToBottom()
                                                self?.addMessageListener()
                                                UIView.animate(withDuration: 1) {
                                                    self?.loadingMessagesImage.layer.opacity = 0
                                                } completion: { isComplite in
                                                    if isComplite {
                                                        self?.loadingMessagesImage.stop()
                                                        self?.loadingMessagesImage.isHidden = true
                                                        self?.loadingMessagesImage.layer.opacity = 1
                                                        
                                                    }
                                                }

                                        
                                            case .failure(_):
                                                PopUpService.shared.showInfo(text: "Ошибка загрузки сообщений")
                                            }
                                        })
    }
    
    //MARK: newMessage
    func newMessage() {
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    //MARK: configureInputBar
    private func configureInputBar() {
        messageInputBar.isTranslucent = false
        messageInputBar.backgroundView.backgroundColor = .myWhiteColor()
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.middleContentView?.backgroundColor = .myWhiteColor()
        let sendImage = UIImage(systemName: "arrow.turn.right.up", withConfiguration: UIImage.SymbolConfiguration(font: .avenirRegular(size: 24), scale: UIImage.SymbolScale.default))
        messageInputBar.sendButton.setImage(sendImage, for: .normal)
        messageInputBar.sendButton.tintColor = .myLabelColor()
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.setSize(CGSize(width: 36 , height: 36), animated: false)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.rightStackView.axis = .horizontal
        messageInputBar.inputTextView.placeholder = "Сообщение..."
        messageInputBar.inputTextView.keyboardDismissMode = .interactive
        messageInputBar.inputTextView.isImagePasteEnabled = false
        messageInputBar.inputTextView.placeholderLabel.font = .avenirRegular(size: 16)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.inputTextView.backgroundColor = .myWhiteColor()
        messageInputBar.middleContentViewPadding.right = -38
        messageInputBar.middleContentViewPadding.top = 20
    }
    
    //MARK: configureCameraBar
    private func configureCameraBar() {
        let cameraItem = InputBarButtonItem()
        cameraItem.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .avenirRegular(size: 24), scale: UIImage.SymbolScale.large))
        cameraItem.tintColor = .myLabelColor()
        cameraItem.setSize(CGSize(width: 36, height: 36), animated: false)
        cameraItem.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        cameraItem.addTarget(self, action: #selector(tuppedSendImage), for: .primaryActionTriggered)
        
        messageInputBar.leftStackView.axis = .horizontal
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    
    //MARK: showTimerPopUp
    private func showTimerPopUp() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let strongChat = chat
        var messageText = ""
        var okButtonText = ""
        let timeToDeleteChat = chat.createChatDate.getPeriodToDate(periodMinuteCount: MChat.getDefaultPeriodMinutesOfLifeChat())
        if currentPeopleDelegate.currentPeople.isGoldMember || currentPeopleDelegate.currentPeople.isTestUser {
            messageText = "У тебя Flava premium, можешь остановить таймер удаления без подтверждения собеседника"
            okButtonText = "Остановить таймер"
        } else {
            messageText = "Отправь запрос на остановку таймера, если собеседник подтвердит, чат не будет удален"
            okButtonText = "Отправить"
        }
        
        if !chat.currentUserIsWantStopTimer {
            PopUpService.shared.showInfoWithButtonPopUp(header: "Чат будет удален через \(timeToDeleteChat)",
                                              text: messageText,
                                              cancelButtonText: "Позже",
                                              okButtonText: okButtonText,
                                              font: .avenirBold(size: 14)) {
                FirestoreService.shared.deactivateChatTimer(currentUser: currentPeopleDelegate.currentPeople, chat: strongChat) { _  in }
            }
        } else if !chat.friendIsWantStopTimer {
            PopUpService.shared.showInfo(text: """
                                                Собеседник не отключил таймер,
                                                чат будет удален через \(timeToDeleteChat)
                                               """)
        }
    }
    
    //MARK: sendImage
    private func sendImage(image: UIImage) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        StorageService.shared.uploadChatImage(image: image,
                                              currentUserID: currentPeopleDelegate.currentPeople.senderId,
                                              chat: chat) {[weak self] result in
            switch result {
            
            case .success(let url):
                guard let chat = self?.chat else { return }
                var imageMessage = MMessage(user: currentPeopleDelegate.currentPeople, image: image)
                imageMessage.imageURL = url
                FirestoreService.shared.sendMessage(chat: chat,
                                                    currentUser: currentPeopleDelegate.currentPeople,
                                                    message: imageMessage) { result in
                    switch result {
                    
                    case .success():
                        //send notification to friend
                        if chat.fcmKey != "" {
                            PushMessagingService.shared.sendMessageToToken(token: chat.fcmKey,
                                                                           header: currentPeopleDelegate.currentPeople.displayName,
                                                                           text: "Фото")
                        } else {
                            //push to topic
                            PushMessagingService.shared.sendMessageToUser(currentUser: currentPeopleDelegate.currentPeople,
                                                                          toUserID: chat,
                                                                          header: currentPeopleDelegate.currentPeople.displayName,
                                                                          text: "Фото")
                        }
                        
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                }
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

//MARK: objc
extension ChatViewController {
    
    
    //MARK: sceneDidChanged
    @objc private func sceneDidChanged(notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            acceptChatDelegate?.messageCollectionViewDelegate = self
            print("get back!!!!")
        case UIApplication.willTerminateNotification:
            print("get back!!!!")
        default:
            break
        }
        
       
    }
    
    //MARK: keyboardNotification
    @objc private func keyboardNotification(notification: Notification) {
        
        if notification.name == UIResponder.keyboardWillShowNotification  {
            
            messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    //MARK: tuppedSendImage
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
    
    //MARK: screenshotTaken
    @objc private func screenshotTaken(){
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let text = currentPeopleDelegate.currentPeople.displayName + MLabels.screenshotTaken.rawValue
        
        FirestoreService.shared.sendAdminMessage(currentUser: currentPeopleDelegate.currentPeople,
                                                 chat: chat,
                                                 text: text) { [weak self] _ in
            
            //send notification to friend
            guard let chat = self?.chat else { return }
            if chat.fcmKey != "" {
                PushMessagingService.shared.sendMessageToToken(token: chat.fcmKey,
                                                               header: MAdmin.displayName.rawValue,
                                                               text: text)
            } else {
                //push to topic
                PushMessagingService.shared.sendMessageToUser(currentUser: currentPeopleDelegate.currentPeople,
                                                              toUserID: chat,
                                                              header: MAdmin.displayName.rawValue,
                                                              text: text)
            }
            
        }
    }
    
    //MARK: screenIsCaptured
    @objc private func screenIsCaptured(){
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let text = currentPeopleDelegate.currentPeople.displayName + MLabels.isCapturedScreen.rawValue
        
        FirestoreService.shared.sendAdminMessage(currentUser: currentPeopleDelegate.currentPeople,
                                                 chat: chat,
                                                 text: text) { [weak self] _ in
            
            //send notification to friend
            guard let chat = self?.chat else { return }
            if chat.fcmKey != "" {
                PushMessagingService.shared.sendMessageToToken(token: chat.fcmKey,
                                                               header: MAdmin.displayName.rawValue,
                                                               text: text)
            } else {
                //push to topic
                PushMessagingService.shared.sendMessageToUser(currentUser: currentPeopleDelegate.currentPeople,
                                                              toUserID: chat,
                                                              header: MAdmin.displayName.rawValue,
                                                              text: text)
            }
        }
    }
    
    //MARK: profileTapped
    @objc private func profileTapped() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let profileVC = PeopleInfoViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                 peopleID: chat.friendId,
                                                 isFriend: true,
                                                 requestChatsDelegate: requestDelegate,
                                                 peopleDelegate: peopleDelegate,
                                                 reportDelegate: reportDelegate)
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    //MARK: profileTapped
    @objc private func chatSettingsTapped() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let settingsVC = SetupChatMenu(currentPeopleDelegate: currentPeopleDelegate,
                                       chat: chat,
                                       reportDelegate: reportDelegate,
                                       peopleDelegate: peopleDelegate,
                                       requestDelegate: requestDelegate,
                                       messageControllerDelegate: self)
        
        settingsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingsVC, animated: true)
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
    
    //MARK: showDeleteChatAlert
    func showChatAlert(text: String) {
        //need remove lister, else if user take screenshot, chate recreate with send admin message
        removeListners()
        
        let alert = UIAlertController(title: nil,
                                      message: text,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Понятно",
                                     style: .default) {[weak self] _ in
            
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        alert.setMyLightStyle()
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
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
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        return currentPeopleDelegate.currentPeople
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        guard let messageDelegate = messageDelegate else { fatalError("Can' get messageDelegate") }
        return messageDelegate.messages[indexPath.row]
        
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        1
    }
    
    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageDelegate?.messages.count ?? 0
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let currentTime = MessageKitDateFormatter.shared.string(from: message.sentDate)
        let attributedDateString = NSAttributedString(string: currentTime,
                                                      attributes: [NSAttributedString.Key.font : UIFont.avenirRegular(size: 12),
                                                                   NSAttributedString.Key.foregroundColor : UIColor.myGrayColor()])
        
        if indexPath.row == 0 {
            return attributedDateString
        } else {
            guard let messageDelegate = messageDelegate else { return nil }
            //if from previus message more then 10 minets show time
            let timeDifference = messageDelegate.messages[indexPath.row - 1].sentDate.distance(to: message.sentDate) / 600
            
            if timeDifference > 1 {
                return attributedDateString
            }
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if message.sender.senderId == MAdmin.id.rawValue {
            return NSAttributedString(string: message.sender.displayName,
                                      attributes: [NSAttributedString.Key.font : UIFont.avenirRegular(size: 12),
                                                   NSAttributedString.Key.foregroundColor : UIColor.myGrayColor()])
        } else {
            return nil
        }
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let messageDelegate = messageDelegate else { fatalError() }
        let sawAllMessageText = chat.friendSawAllMessageInChat ? "Просмотрено" : "Отправлено"
        let color: UIColor = chat.friendSawAllMessageInChat ? .myLabelColor() : .myGrayColor()
        let attributedString = NSAttributedString(string: sawAllMessageText,
                                                  attributes: [NSAttributedString.Key.font : UIFont.avenirRegular(size: 12),
                                                               NSAttributedString.Key.foregroundColor : color])
        let isLastMessage = indexPath.row == messageDelegate.messages.count - 1
        if isFromCurrentSender(message: message) && isLastMessage {
            return attributedString
        } else {
            return nil
        }
    }

}

//MARK: MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        CGSize(width: 0, height: 9)
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        } else {
            guard let messageDelegate = messageDelegate else { return 0 }
            //if from previus message more then 10 minets set new height
            let timeDifference = messageDelegate.messages[indexPath.row - 1].sentDate.distance(to: message.sentDate) / 600
            if timeDifference > 1 {
                return 50
            }
            //if last message not from penultimate message sender
            if messageDelegate.messages[indexPath.row - 1].sender.senderId != message.sender.senderId {
                return 30
            }
        }
        return 0
    }
    
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        //if sender of message - Admin, set more Height to label in messageTop
        if message.sender.senderId == MAdmin.id.rawValue {
            return 20
        } else {
            return 0
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        guard let messageDelegate = messageDelegate else { return 0 }
        let isLastMessage = indexPath.row == messageDelegate.messages.count - 1
        if isFromCurrentSender(message: message) && isLastMessage {
            return 20
        } else {
            return 0
        }
    }
}

//MARK: MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return .myMessageColor()
        } else if message.sender.senderId == MAdmin.id.rawValue {
            return .adminMessageColor()
        } else {
            return .friendMessageColor()
        }
        
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return .myWhiteColor()
        } else if message.sender.senderId == MAdmin.id.rawValue {
            return .white
        } else {
            return .myLabelColor()
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
//        .bubbleTail(isFromCurrentSender(message: message) ? MessageStyle.TailCorner.bottomRight : MessageStyle.TailCorner.bottomLeft, MessageStyle.TailStyle.pointedEdge)
        let messageCount = messageDelegate?.messages.count ?? 0
        let tailCorner = isFromCurrentSender(message: message) ? MessageStyle.TailCorner.bottomRight : MessageStyle.TailCorner.bottomLeft
        if indexPath.row == messageCount - 1 {
            //if last message, show tail
            return .bubbleTail(tailCorner, .pointedEdge)
        } else if message.sender.senderId  == messageDelegate?.messages[indexPath.row + 1].sender.senderId {
            //if next message from this user too
            return .bubble
        } else {
            return .bubbleTail(tailCorner, .pointedEdge)
        }
        
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

//
extension ChatViewController: MessageCellDelegate {
    func didTapBackground(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
}

//MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("CurrentPeopleDelegate is nil in ChatVC")}
        
        let sender = MSender(senderId: currentPeopleDelegate.currentPeople.senderId,
                             displayName: currentPeopleDelegate.currentPeople.displayName)
        let message = MMessage(user: sender, content: text)
        let strongChat = chat
        
        FirestoreService.shared.sendMessage(chat: chat,
                                            currentUser: currentPeopleDelegate.currentPeople,
                                            message: message) { result in
            switch result {
            
            case .success():
                //send notification to friend
                if strongChat.fcmKey != "" {
                    PushMessagingService.shared.sendMessageToToken(token: strongChat.fcmKey,
                                                                   header: currentPeopleDelegate.currentPeople.displayName,
                                                                   text: text)
                } else {
                    //push to topic
                    PushMessagingService.shared.sendMessageToUser(currentUser: currentPeopleDelegate.currentPeople,
                                                                  toUserID: strongChat,
                                                                  header: currentPeopleDelegate.currentPeople.displayName,
                                                                  text: text)
                }
               
               
              
            case .failure(_):
                //no document to update
                break
            }
        }
        inputBar.inputTextView.text = ""
    }
}

extension ChatViewController {
    private func setupConstraints() {
        loadingMessagesImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingMessagesImage)
        
        NSLayoutConstraint.activate([
            loadingMessagesImage.topAnchor.constraint(equalTo: view.topAnchor),
            loadingMessagesImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingMessagesImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingMessagesImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
