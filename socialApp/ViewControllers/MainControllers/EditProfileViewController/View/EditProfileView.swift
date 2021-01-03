//
//  EditProfileView.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class EditProfileView: UIView {
    private let scrollView = UIScrollView()
    private let gelleryScrollView = GalleryView(profileImage: "", gallery: [:], showPrivate: true, showProtectButton: true)
    private let nameLabel = UILabel(labelText: "Имя:",
                            textFont: .avenirRegular(size: 16),
                            textColor: .myGrayColor())
    private let aboutLabel = UILabel(labelText: "Обо мне:",
                             textFont: .avenirRegular(size: 16),
                             textColor: .myGrayColor())
    private let genderButton = OneLineButtonWithHeader(header: "Гендер", info: "")
    private let sexualityButton = OneLineButtonWithHeader(header: "Сексуальная ориентация", info: "")
    private let nameTextField = OneLineTextField(isSecureText: false,
                                         tag: 1,
                                         placeHoledText: "")
    private let interestsTags = TagsCollectionView(unselectTags: [],
                                           selectTags: [],
                                           headerText: "Интересы",
                                           headerFont: .avenirRegular(size: 16),
                                           headerColor: .myGrayColor(),
                                           textFieldPlaceholder: "Новый интерес...")
    private let desireTags = TagsCollectionView(unselectTags: [],
                                           selectTags: [],
                                           headerText: "Твои желания",
                                           headerFont: .avenirRegular(size: 16),
                                           headerColor: .myGrayColor(),
                                           textFieldPlaceholder: "Новое желание...")
    private let advertTextView = UITextView(text: "",
                                    isEditable: true)
    
    private let editPhotosButton = RoundButton(newBackgroundColor: UIColor.myFirstButtonColor().withAlphaComponent(0.5),
                                       title: "Редактировать фото",
                                       titleColor: .myFirstButtonLabelColor())
    private let previewButton = RoundButton(newBackgroundColor: UIColor.myFirstButtonColor(),
                                            title: "Предпросмотр профиля",
                                            titleColor: .myFirstButtonLabelColor())
    private let incognitoLabel = UILabel(labelText: "Инкогнито",
                                textFont: .avenirRegular(size: 16),
                                textColor: .mySecondSatColor())
    private let incognitoAboutLabel = UILabel(labelText: "Тебя не увидят другие пользователи, пока ты не поставишь им лайк",
                                textFont: .avenirRegular(size: 16),
                                textColor: .mySecondColor(),
                                linesCount: 0)
    private let incognitoSwitch = UISwitch()
    
    private var selectedVisibleYValue: CGFloat?
    private var keybordMinYValue:CGFloat?
    private var currentPeople: MPeople?
    weak var delegate: EditProfileViewDelegate?
    
    override init(frame: CGRect){
        super.init(frame: frame)
        setup()
        setupNotifications()
        setupButtonAction()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: setup
    private func setup() {
        backgroundColor = .myWhiteColor()
        
        scrollView.delegate = self
        scrollView.addSingleTapRecognizer(target: self, selector: #selector(endEditing))
       
        advertTextView.delegate = self
        nameTextField.delegate = self
        interestsTags.tagsDelegate = self
        desireTags.tagsDelegate = self
        
        gelleryScrollView.layer.cornerRadius = 0
        advertTextView.addDoneButton()
        editPhotosButton.layoutIfNeeded()
        incognitoSwitch.tintColor = .mySecondSatColor()
        incognitoSwitch.onTintColor = .mySecondColor()
        incognitoSwitch.thumbTintColor = .myWhiteColor()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateView(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateView(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    //MARK:  setupButtonAction
    private func setupButtonAction() {
        editPhotosButton.addTarget(self, action: #selector(editPhotosButtonTap), for: .touchUpInside)
        genderButton.addTarget(self, action: #selector(genderSelectTapped), for: .touchUpInside)
        sexualityButton.addTarget(self, action: #selector(sexualitySelectTapped), for: .touchUpInside)
        incognitoSwitch.addTarget(self, action: #selector(incognitoSwitchChanged), for: .touchUpInside)
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
    }
    
    //MARK: setData
    func setData(people: MPeople){
        currentPeople = people
        interestsTags.configure(unselectTags: [],
                                selectedTags: people.interests)
        desireTags.configure(unselectTags: [],
                             selectedTags: people.desires)
        
        gelleryScrollView.setupImages(profileImage: people.userImage,
                                      gallery: people.gallery,
                                      showPrivate: true,
                                      showProtectButton: true,
                                      complition: {
                                        self.gelleryScrollView.layoutSubviews()
        })
        
        nameTextField.text = people.displayName
        advertTextView.text = people.advert
        genderButton.infoLabel.text = people.gender
        sexualityButton.infoLabel.text = people.sexuality
        incognitoSwitch.isOn = people.isIncognito
    }
    
    //MARK: getData
    func getData() -> MPeople? {
        guard let currentPeople = currentPeople else { return nil }
        
        let name = nameTextField.text ?? ""
        let advert = advertTextView.text ?? ""
        let isIncognito = incognitoSwitch.isOn
        let interestsSelectedTags = interestsTags.getSelectedTags()
        let desiresSelectedTags = desireTags.getSelectedTags()
        let gender = genderButton.infoLabel.text ?? MGender.man.rawValue
        let sexuality = sexualityButton.infoLabel.text ?? MSexuality.straight.rawValue
        
        var editedPeople = currentPeople
        editedPeople.displayName = name
        editedPeople.advert = advert
        editedPeople.isIncognito = isIncognito
        editedPeople.interests = interestsSelectedTags
        editedPeople.desires = desiresSelectedTags
        editedPeople.gender = gender
        editedPeople.sexuality = sexuality
        
        return editedPeople
    }
    
    func newValueSelect(gender: String?, sexuality: String?) {
        if let gender = gender {
            genderButton.infoLabel.text = gender
        }
        
        if let sexuality = sexuality {
            sexualityButton.infoLabel.text = sexuality
        }
    }
    
    func prepareForReuse(){
        gelleryScrollView.prepareReuseScrollView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.updateContentView()
    }
}

extension EditProfileView {
    
    //MARK: editPhotosButtonTap
    @objc func editPhotosButtonTap() {
        delegate?.editPhotosButtonTap()
    }
    
    //MARK: genderSelectTapped
    @objc private func genderSelectTapped() {
        delegate?.genderSelectTapped(selectedGender: genderButton.infoLabel.text ?? MGender.man.rawValue)
    }

    //MARK: sexualitySelectTapped
    @objc private func sexualitySelectTapped() {
        delegate?.sexualitySelectTapped(selectedSexuality: sexualityButton.infoLabel.text ?? MSexuality.straight.rawValue)
    }
    
    //MARK: incognitoSwitchChanged
    @objc private func incognitoSwitchChanged(){
        guard let people = currentPeople else { return }
        
        if !PurchasesService.shared.checkActiveSubscribtionWithApphud() && !people.isTestUser {
            delegate?.incognitoSwitchChanged()
            incognitoSwitch.isOn.toggle()
        }
    }
    
    @objc private func previewTapped() {
        delegate?.previewTapped()
    }
    
    
    //MARK: updateView
    @objc func updateView(notification: Notification?) {
        
        let info = notification?.userInfo
        guard let keyboardSize = info?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let size = keyboardSize.cgRectValue
        let toolBarHight:CGFloat = 100
        keybordMinYValue = size.minY
        
        if notification?.name == UIResponder.keyboardWillShowNotification  {
         
        guard let value = selectedVisibleYValue else { return }
            let scrollValue  = value - size.minY + toolBarHight
            let scrollPoint = CGPoint(x: 0, y: scrollValue)
            scrollView.setContentOffset(scrollPoint, animated: true)
        }
        
        if notification?.name == UIResponder.keyboardWillHideNotification {
           // view.frame.origin.y = 0
        }
    }
    
    //MARK: forceUpdateContentOffset
    private func forceUpdateContentOffset(inset: CGFloat) {
        guard let keyboardYValue = keybordMinYValue else { return }
        let toolBarHight:CGFloat = 100
        guard let value = selectedVisibleYValue else { return }
        let scrollValue  = value - keyboardYValue + toolBarHight + inset
        let scrollPoint = CGPoint(x: 0, y: scrollValue)
        scrollView.setContentOffset(scrollPoint, animated: true)
    }
}

//MARK:  UITextFieldDelegate
extension EditProfileView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        selectedVisibleYValue = textField.frame.maxY
        return true
    }
}

//MARK:  UITextViewDelegate
extension EditProfileView:UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        selectedVisibleYValue = textView.frame.maxY
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        selectedVisibleYValue = textView.frame.maxY
        let textViewToolBarHight:CGFloat = 20
        forceUpdateContentOffset(inset: textViewToolBarHight)
    }
}

//MARK:  TagsCollectionViewDelegate
extension EditProfileView: TagsCollectionViewDelegate {
    
    func tagTextFiledShouldReturn(tagsCollectionView: TagsCollectionView, text: String) {
        scrollView.updateContentView()
        selectedVisibleYValue = tagsCollectionView.frame.maxY
        forceUpdateContentOffset(inset: 0)
    }
    
    func tagTextFiledDidBeginEditing(tagsCollectionView: TagsCollectionView) {
        selectedVisibleYValue = tagsCollectionView.frame.maxY
    }
    
    func tagTextConstraintsDidChange(tagsCollectionView: TagsCollectionView) {
        scrollView.updateContentView()
    }
}

//MARK:  setupConstraints
extension EditProfileView {
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        gelleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        editPhotosButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        interestsTags.translatesAutoresizingMaskIntoConstraints = false
        desireTags.translatesAutoresizingMaskIntoConstraints = false
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        advertTextView.translatesAutoresizingMaskIntoConstraints = false
        genderButton.translatesAutoresizingMaskIntoConstraints = false
        sexualityButton.translatesAutoresizingMaskIntoConstraints = false
        incognitoLabel.translatesAutoresizingMaskIntoConstraints = false
        incognitoAboutLabel.translatesAutoresizingMaskIntoConstraints = false
        incognitoSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scrollView)
        scrollView.addSubview(gelleryScrollView)
        scrollView.addSubview(editPhotosButton)
        scrollView.addSubview(previewButton)
        scrollView.addSubview(nameLabel)
        scrollView.addSubview(nameTextField)
        scrollView.addSubview(interestsTags)
        scrollView.addSubview(desireTags)
        scrollView.addSubview(aboutLabel)
        scrollView.addSubview(advertTextView)
        scrollView.addSubview(genderButton)
        scrollView.addSubview(sexualityButton)
        scrollView.addSubview(incognitoLabel)
        scrollView.addSubview(incognitoAboutLabel)
        scrollView.addSubview(incognitoSwitch)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            gelleryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gelleryScrollView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            gelleryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gelleryScrollView.heightAnchor.constraint(equalTo: gelleryScrollView.widthAnchor),
            
            editPhotosButton.bottomAnchor.constraint(equalTo: gelleryScrollView.bottomAnchor, constant: -25),
            editPhotosButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            editPhotosButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            editPhotosButton.heightAnchor.constraint(equalTo: editPhotosButton.widthAnchor, multiplier: 1.0/7.28),
            
            previewButton.topAnchor.constraint(equalTo: gelleryScrollView.bottomAnchor, constant: 35),
            previewButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            previewButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            previewButton.heightAnchor.constraint(equalTo: previewButton.widthAnchor, multiplier: 1.0/7.28),
            
            nameLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 35),
            nameLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            nameLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            nameTextField.heightAnchor.constraint(equalToConstant: 25),
            nameTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            nameTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            interestsTags.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 15),
            interestsTags.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            interestsTags.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            desireTags.topAnchor.constraint(equalTo: interestsTags.bottomAnchor, constant: 15),
            desireTags.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            desireTags.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            aboutLabel.topAnchor.constraint(equalTo: desireTags.bottomAnchor, constant: 35),
            aboutLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25),
            aboutLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            advertTextView.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor),
            advertTextView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            advertTextView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            genderButton.topAnchor.constraint(equalTo: advertTextView.bottomAnchor, constant: 35),
            genderButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            genderButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            genderButton.heightAnchor.constraint(equalToConstant: 70),
            
            sexualityButton.topAnchor.constraint(equalTo: genderButton.bottomAnchor, constant: 25),
            sexualityButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            sexualityButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            sexualityButton.heightAnchor.constraint(equalToConstant: 70),
            
            incognitoLabel.topAnchor.constraint(equalTo: sexualityButton.bottomAnchor, constant: 35),
            incognitoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            incognitoLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            incognitoSwitch.topAnchor.constraint(equalTo: incognitoLabel.topAnchor),
            incognitoSwitch.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            incognitoAboutLabel.topAnchor.constraint(equalTo: incognitoSwitch.bottomAnchor, constant: 10),
            incognitoAboutLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            incognitoAboutLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -55),
            incognitoAboutLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
        ])
    }
}
