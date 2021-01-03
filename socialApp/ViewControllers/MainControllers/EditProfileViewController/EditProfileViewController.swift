//
//  SetProfileViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 04.07.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SwiftUI
import FirebaseAuth
import SDWebImage
import MapKit

class EditProfileViewController: UIViewController {
    
    private var isComeFromePreview = false
    private var editProfileView = EditProfileView()
    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?) {
        self.currentPeopleDelegate = currentPeopleDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        setupVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController()
        registerNotification()
        setPeopleData()
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        savePeopleData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        editProfileView.setNeedsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editProfileView.prepareForReuse()
    }

    private func setupVC() {
        view.backgroundColor = .myWhiteColor()
        editProfileView.delegate = self
    }
    
    //MARK:  setupNavigationController
    private func setupNavigationController(){
        navigationItem.title = "Профиль"
        navigationItem.backButtonTitle = ""
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func registerNotification() {
        NotificationCenter.addObsorverToPremiumUpdate(observer: self,
                                                      selector: #selector(premiumIsUpdated))
    }
    
    //MARK:  setPeopleData
    private func setPeopleData() {
        
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in EditProfileVC") }
        let people = currentPeopleDelegate.currentPeople
        
        editProfileView.setData(people: people)
    }
    
    //MARK:  savePeopleData
    private func savePeopleData() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in EditProfileVC") }
        var people = currentPeopleDelegate.currentPeople
        
        if let editedPeople = editProfileView.getData() {
            people = editedPeople
        }
        
        FirestoreService.shared.saveProfileAfterEdit(id: people.senderId,
                                                     name: people.displayName,
                                                     advert: people.advert,
                                                     gender: people.gender,
                                                     sexuality: people.sexuality,
                                                     interests: people.interests,
                                                     desires: people.desires,
                                                     isIncognito: people.isIncognito) { result in
            switch result {
            
            case .success():
                return
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension EditProfileViewController : EditProfileViewDelegate {
    func previewTapped() {
        guard let previewPeople = editProfileView.getData() else { return }
        let previewVC = PeopleInfoViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                 peopleID: "",
                                                 isFriend: true,
                                                 isCurrentPeople: true,
                                                 previewPeople: previewPeople,
                                                 requestChatsDelegate: nil,
                                                 peopleDelegate: nil,
                                                 reportDelegate: nil)
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    func editPhotosButtonTap() {
        let vc = EditPhotoViewController(currentPeopleDelegate: currentPeopleDelegate,
                                         isFirstSetup: false)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func genderSelectTapped(selectedGender: String) {
        let vc = SelectionViewController(elements: MGender.modelStringAllCases,
                                         description: MGender.description,
                                         selectedValue: selectedGender,
                                         complition: {[weak self] selected in
                                            self?.editProfileView.newValueSelect(gender: selected,
                                                                                 sexuality: nil)
                                         })
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }
    
    func sexualitySelectTapped(selectedSexuality: String) {
        let vc = SelectionViewController(elements: MSexuality.modelStringAllCases,
                                         description: MSexuality.description,
                                         selectedValue: selectedSexuality,
                                         complition: { [weak self] selected in
                                            self?.editProfileView.newValueSelect(gender: nil,
                                                                                 sexuality: selected)
                                         })
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }
    
    func incognitoSwitchChanged() {
        PopUpService.shared.bottomPopUp(header: "Режим инкогнито",
                                        text: "Данный режим доступен с подпиской Flava premium",
                                        image: nil,
                                        okButtonText: "Перейти на Flava premium") { [weak self] in
            
            let purchasVC = PurchasesViewController(currentPeopleDelegate: self?.currentPeopleDelegate)
            purchasVC.modalPresentationStyle = .fullScreen
            self?.present(purchasVC, animated: true, completion: nil)
        }
    }
}

//MARK: objc extension
extension EditProfileViewController {
    
    //MARK: endEditing
    @objc func endEditing() {
        editProfileView.endEditing(true)
    }
    
    @objc private func premiumIsUpdated() {
        setPeopleData()
    }
}

//MARK:  setupConstraints
extension EditProfileViewController {
    
    private func setupConstraints() {
        editProfileView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(editProfileView)
        
        NSLayoutConstraint.activate([
            editProfileView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            editProfileView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            editProfileView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editProfileView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

