//
//  PopUpService.swift
//  socialApp
//
//  Created by Денис Щиголев on 06.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SwiftEntryKit
import SDWebImage

class PopUpService {
    static let shared = PopUpService()
    
    private weak var acceptChatsDelegate: AcceptChatListenerDelegate?
    private weak var requestChatsDelegate: RequestChatListenerDelegate?
    private weak var peopleDelegate: PeopleListenerDelegate?
    private weak var likeDislikeDelegate: LikeDislikeListenerDelegate?
    private weak var messageDelegate: MessageListenerDelegate?
    private weak var reportsDelegate: ReportsListnerDelegate?
    
    private init() {}
}

extension PopUpService {
    
    func setupDelegate(acceptChatsDelegate: AcceptChatListenerDelegate?,
                       requestChatsDelegate: RequestChatListenerDelegate?,
                       peopleDelegate: PeopleListenerDelegate?,
                       likeDislikeDelegate: LikeDislikeListenerDelegate?,
                       messageDelegate: MessageListenerDelegate?,
                       reportsDelegate: ReportsListnerDelegate?) {
        self.acceptChatsDelegate = acceptChatsDelegate
        self.requestChatsDelegate  = requestChatsDelegate
        self.peopleDelegate = peopleDelegate
        self.messageDelegate = messageDelegate
        self.reportsDelegate = reportsDelegate
    }
    
    //MARK: showMatchPopUP
    func showMatchPopUP(currentPeople: MPeople,
                        chat: MChat,
                        action: @escaping(MessageListenerDelegate, AcceptChatListenerDelegate)->(),
                        cancelAction: (()->Void)? = nil) {
        let matchPopUpView = MatchViewPopUp(currentPeople: currentPeople,
                                            chat: chat) { [weak self] in
            if let messageDelegate = self?.messageDelegate, let acceptChatsDelegate = self?.acceptChatsDelegate {
                action(messageDelegate, acceptChatsDelegate)
            }
        }
        if let cancelAction = cancelAction {
            matchPopUpView.cancelAction = cancelAction
        }
        
        var attributes = EKAttributes()
        attributes.name = "Bottom Match"
        attributes.displayMode = .inferred
        attributes.statusBar = .inferred
        attributes.displayDuration = .infinity
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.screenBackground = .color(color: EKColor.init(UIColor.myLabelColor().withAlphaComponent(0.5)))
        attributes.position = .bottom
        attributes.hapticFeedbackType = .warning
        attributes.positionConstraints.safeArea = .overridden
        SwiftEntryKit.display(entry: matchPopUpView, using: attributes)
    }
    
    //MARK: showAnimatateView
    func showAnimateView(name: String) {
        let view = LoadingView(name: name, isHidden: false)
        
        var attributes = EKAttributes()
        attributes.name = name
        attributes.displayMode = .inferred
        attributes.windowLevel = .custom(level: .normal + 1)
        attributes.statusBar = .inferred
        attributes.displayDuration = .infinity
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .absorbTouches
        attributes.scroll = .disabled
        attributes.entranceAnimation = .none
        attributes.exitAnimation = .init(translate: nil,
                                         scale: nil,
                                         fade: .init(from: 1, to: 0, duration: 0.3))
//        attributes.exitAnimation = .none
        attributes.screenBackground = .color(color: EKColor.init(UIColor.myLabelColor().withAlphaComponent(0.5)))
        attributes.position = .bottom
        attributes.hapticFeedbackType = .none
        attributes.positionConstraints = EKAttributes.PositionConstraints.fullScreen
        attributes.positionConstraints.safeArea = .overridden
      //  SwiftEntryKit.display(entry: view, using: attributes, presentInsideKeyWindow: true, rollbackWindow: .main)
        SwiftEntryKit.display(entry: view, using: attributes)
    }
    
    //MARK: showViewPopUp
    func showViewPopUp(view: UIView, withAnimation: Bool, name: String){
        var attributes = EKAttributes()
        attributes.name = name
        attributes.displayMode = .inferred
        attributes.statusBar = .inferred
        attributes.windowLevel = .custom(level: .alert + 1)
        attributes.displayDuration = .infinity
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled
        attributes.screenInteraction = .absorbTouches
        attributes.screenBackground = .color(color: EKColor.init(UIColor.myLabelColor().withAlphaComponent(0.5)))
        attributes.position = .bottom
        if !withAnimation {
            attributes.entranceAnimation = .none
        }
        let constraints = EKAttributes.PositionConstraints.fullScreen
        attributes.positionConstraints = constraints
        attributes.hapticFeedbackType = .error
        attributes.positionConstraints.safeArea = .overridden
        //SwiftEntryKit.display(entry: view, using: attributes)
        SwiftEntryKit.display(entry: view, using: attributes, presentInsideKeyWindow: false, rollbackWindow: .main)
    }
    
    func dismisPopUp(name: String, complition:@escaping()->()) {
        SwiftEntryKit.dismiss(.specific(entryName: name)) {
            complition()
        }
    }
    
    func dismisAllPopUp() {
        SwiftEntryKit.dismiss(.all)
    }
    
    //MARK: bottomPopUp
    func bottomPopUp(header: String,
                     text: String,
                     image: UIImage?,
                     okButtonText: String,
                     okAction: @escaping ()->()) {
       
        var themeImage: EKPopUpMessage.ThemeImage?
        
        if let image = image {
            themeImage = EKPopUpMessage.ThemeImage(
                image: EKProperty.ImageContent(
                    image: image,
                    displayMode: EKAttributes.DisplayMode.inferred,
                    size: CGSize(width: 60, height: 60),
                    tint: EKColor.init(.myLabelColor()),
                    contentMode: .scaleAspectFit
                )
            )
        }
         
        let title = EKProperty.LabelContent(
            text: header,
            style: .init(
                font: .avenirBold(size: 14),
                color: EKColor.init(.myLabelColor()),
                alignment: .center,
                displayMode: EKAttributes.DisplayMode.inferred
            ),
            accessibilityIdentifier: "title"
        )
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .avenirRegular(size: 14),
                color: EKColor.init(.myLabelColor()),
                alignment: .center,
                displayMode: EKAttributes.DisplayMode.inferred
            ),
            accessibilityIdentifier: "description"
        )
        let okButton = EKProperty.ButtonContent(
            label: .init(
                text: okButtonText,
                style: .init(
                    font: .avenirBold(size: 14),
                    color: EKColor.init(.white),
                    displayMode: EKAttributes.DisplayMode.inferred
                )
            ),
            backgroundColor: EKColor.init(.mySecondColor()),
            highlightedBackgroundColor: EKColor.init(.mySecondSatColor()),
            displayMode: EKAttributes.DisplayMode.inferred,
            accessibilityIdentifier: "okButton")
        
        
        let message = EKPopUpMessage(
            themeImage: themeImage,
            title: title,
            description: description,
            button: okButton) {
            okAction()
            SwiftEntryKit.dismiss()
        }
        let contentView = EKPopUpMessageView(with: message)
        
        var attributes = EKAttributes()
        attributes.displayMode = .inferred
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.position = .bottom
        attributes.displayDuration = .infinity
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.entranceAnimation = .init(
            translate: .init(
                duration: 0.5,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.entryBackground = .visualEffect(style: .init(style: .systemMaterial))
        attributes.positionConstraints = .fullWidth
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    //MARK: showInfoPopUp
    func showInfoWithButtonPopUp(header: String,
                       text: String,
                       cancelButtonText: String,
                       okButtonText: String,
                       font: UIFont,
                       okButtonAction: @escaping () -> ()) {
        let simpleMessage = EKSimpleMessage(image: nil,
                                            title: .init(text: header,
                                                         style: .init(font: font,
                                                                      color: EKColor(.myLabelColor()),
                                                                      alignment: .center,
                                                                      displayMode: .inferred,
                                                                      numberOfLines: 1)),
                                            description: .init(text: text,
                                                               style: .init(font: .avenirRegular(size: 14),
                                                                            color: EKColor(.myLabelColor()),
                                                                            alignment: .center,
                                                                            displayMode: .inferred,
                                                                            numberOfLines: 0)))
        let okButtonContent = EKProperty.ButtonContent.init(label: .init(text: okButtonText,
                                                                         style: .init(font: font,
                                                                                      color: .init(.myLabelColor()))),
                                                            backgroundColor: .init(.myLightGrayColor()),
                                                            highlightedBackgroundColor: .init(.myGrayColor())) {
            SwiftEntryKit.dismiss()
            okButtonAction()
        }
        
        let cancelButtonContent = EKProperty.ButtonContent.init(label: .init(text: cancelButtonText,
                                                                             style: .init(font: font,
                                                                                          color: .init(.myLabelColor()))),
                                                                backgroundColor: .init(.myLightGrayColor()),
                                                                highlightedBackgroundColor: .init(.myGrayColor())) {
            SwiftEntryKit.dismiss()
        }
        
        let buttonBarContent = EKProperty.ButtonBarContent(with: [cancelButtonContent,okButtonContent], separatorColor: .clear, expandAnimatedly: true)
        let message = EKAlertMessage(simpleMessage: simpleMessage,
                                     buttonBarContent: buttonBarContent)
        let infoView = EKAlertMessageView(with: message)
        
        var infoPopUpAttributes = EKAttributes()
        infoPopUpAttributes.displayDuration = 4
        infoPopUpAttributes.position = .top
        infoPopUpAttributes.hapticFeedbackType = .warning
        infoPopUpAttributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        infoPopUpAttributes.entryInteraction = .absorbTouches
        infoPopUpAttributes.entryBackground = .color(color: .init(.myLightGrayColor()))
        SwiftEntryKit.display(entry: infoView, using: infoPopUpAttributes)
    }
    
    //MARK: showMessagePopUp
    func showMessagePopUp(header: String, text: String, time: String, imageStringURL: String){
        
        var attributes = EKAttributes()
        attributes = .topToast
        attributes.name = "Top Message"
        attributes.hapticFeedbackType = .success
        attributes.displayMode = .inferred
        attributes.statusBar = .inferred
        attributes.entryBackground = .color(color: .init(.myLightGrayColor()))
        attributes.entranceAnimation = .translation
        attributes.exitAnimation = .translation
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.displayDuration = 4
        
        let title = EKProperty.LabelContent(
            text: header,
            style: .init(
                font: .avenirBold(size: 12),
                color: .init(.myLabelColor()),
                displayMode: .inferred
            )
        )
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .avenirRegular(size: 12),
                color: .init(.myLabelColor()),
                displayMode: .inferred
            )
        )
        let time = EKProperty.LabelContent(
            text: time,
            style: .init(
                font: .avenirRegular(size: 12),
                color: .init(.myLabelColor()),
                displayMode: .inferred
            )
        )
        
        let imageURL = URL(string: imageStringURL)
        
        //load image and then show popUp
        SDWebImageManager.shared.loadImage(with: imageURL,
                                           options: .highPriority,
                                           progress: nil) { (getedImage, data, error, cache, complite, url) in
            var photoImage = UIImage()
            if let getedImage = getedImage {
                photoImage = getedImage
            }
            
            let image = EKProperty.ImageContent.thumb(
                with: photoImage,
                edgeSize: 34
            )
            
            let simpleMessage = EKSimpleMessage(
                image: image,
                title: title,
                description: description
            )
            let notificationMessage = EKNotificationMessage(
                simpleMessage: simpleMessage,
                auxiliary: time
            )
            let contentView = EKNotificationMessageView(with: notificationMessage)
            
            SwiftEntryKit.display(entry: contentView, using: attributes)
        }
    }
    
    //MARK: show info
    func showInfo(text: String){
        var attributes = EKAttributes()
        attributes = .topNote
        attributes.displayMode = .inferred
        attributes.displayDuration = 3
        attributes.name = "Top Info"
        attributes.hapticFeedbackType = .success
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: .init(.myLightGrayColor()))
    
        let text = text
        let style = EKProperty.LabelStyle(
            font: .avenirRegular(size: 14),
            color: .init(.myLabelColor()),
            alignment: .center,
            numberOfLines: 2
        )
        let labelContent = EKProperty.LabelContent(
            text: text,
            style: style
        )
        let contentView = EKNoteMessageView(with: labelContent)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
     func showProcessingInfo(text: String) {
        var attributes = EKAttributes()
        attributes = .topNote
        attributes.displayMode = .inferred
        attributes.displayDuration = .infinity
        attributes.name = "Top Info with activity"
        attributes.hapticFeedbackType = .success
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: .init(.myLightGrayColor()))
        
        let style = EKProperty.LabelStyle(
            font: .avenirRegular(size: 14),
            color: .black,
            alignment: .center,
            displayMode: .inferred
        )
        let labelContent = EKProperty.LabelContent(
            text: text,
            style: style
        )
        let contentView = EKProcessingNoteMessageView(
            with: labelContent,
            activityIndicator: .medium
        )
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    func dismisProcessingInfo(comlition: (()-> Void)?) {
        SwiftEntryKit.dismiss(.specific(entryName: "Top Info with activity"), with: comlition)
    }
}
