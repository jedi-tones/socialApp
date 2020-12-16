//
//  GenderSelectionTableViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 11.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class GenderSelectionViewController: UIViewController {

    private var userID: String
    
    private let headerLabel = UILabel(labelText: MLabels.genderSelectionHeader.rawValue, textFont: .avenirBold(size: 24),linesCount: 0)
    private let genderSelectionButton = OneLineButtonWithHeader(header: "Гендер", info: "Парень")
    private let sexualitySelectionButton = OneLineButtonWithHeader(header: "Сексуальность", info: "Гетеро")
    private let lookingForSelectionButton = OneLineButtonWithHeader(header: "Кого ты ищешь", info: "Девушку")
    private let nameLabel = UILabel(labelText: "Вымышленное имя", textFont: .avenirRegular(size: 16), textColor: .myGrayColor())
    private let nameTextField = OneLineTextField(isSecureText: false, tag: 1)

    init(userID: String){
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupConstraints()
    }
    
    private func setup() {
        
        view.backgroundColor = .myWhiteColor()
        
        navigationItem.backButtonTitle = "Назад"
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .save,
                                                         target: self,
                                                         action: #selector(saveButtonTapped)),
                                         animated: false)
        
        nameTextField.delegate = self
        
        genderSelectionButton.addTarget(self, action: #selector(genderSelectTapped), for: .touchUpInside)
        sexualitySelectionButton.addTarget(self, action: #selector(sexualitySelectTapped), for: .touchUpInside)
        lookingForSelectionButton.addTarget(self, action: #selector(lookingForSelectTapped), for: .touchUpInside)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: obcj
extension GenderSelectionViewController {
    
    @objc private func saveButtonTapped() {
        let id = userID
        let userName = Validators.shared.isFilledUserName(userName: nameTextField.text)
        if userName.isFilled {
            guard let gender = genderSelectionButton.infoLabel.text else { return }
            guard let sexuality = sexualitySelectionButton.infoLabel.text else { return }
            guard let lookingFor = lookingForSelectionButton.infoLabel.text else { return }
            
            FirestoreService.shared.saveFirstSetupNameGender(id: userID,
                                                             userName: userName.userName,
                                                             gender: gender,
                                                             lookingFor: lookingFor,
                                                             sexuality: sexuality) {[weak self] result in
                switch result {
                
                case .success():
                    
                    self?.view.endEditing(true)
                    let nextViewController = InterestsTagsViewController(userID: id)
                    self?.navigationController?.setViewControllers([nextViewController], animated: true)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
            
        } else {
            PopUpService.shared.bottomPopUp(header: "Укажи имя",
                                            text: "Ты можешь указать любое вымышленное имя",
                                            image: nil,
                                            okButtonText: "Ок") { [weak self] in
                self?.nameTextField.becomeFirstResponder()
            }
        }
    }
    
    @objc private func genderSelectTapped() {
        let vc = SelectionViewController(elements: MGender.modelStringAllCases,
                                         description: MGender.description,
                                         selectedValue: genderSelectionButton.infoLabel.text ?? "",
                                         complition: {[weak self] selected in
                                            self?.genderSelectionButton.infoLabel.text = selected
                                         })
        vc.modalPresentationStyle = .overCurrentContext
        
        present(vc, animated: true, completion: nil)
    }


    @objc private func sexualitySelectTapped() {
        let vc = SelectionViewController(elements: MSexuality.modelStringAllCases,
                                         description: MSexuality.description,
                                         selectedValue: sexualitySelectionButton.infoLabel.text ?? "",
                                         complition: { [weak self] selected in
                                            self?.sexualitySelectionButton.infoLabel.text = selected
                                         })
        vc.modalPresentationStyle = .overCurrentContext
        
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func lookingForSelectTapped() {
        let vc = SelectionViewController(elements: MLookingFor.modelStringAllCases,
                                         description: MLookingFor.description,
                                         selectedValue: lookingForSelectionButton.infoLabel.text ?? "",
                                         complition: { [weak self] selected in
                                            self?.lookingForSelectionButton.infoLabel.text = selected
                                         })
        vc.modalPresentationStyle = .overCurrentContext
        
        present(vc, animated: true, completion: nil)
    }
}

//MARK: textFieldDelegate
extension GenderSelectionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}


//MARK: setupConstraints
extension GenderSelectionViewController {
    private func setupConstraints() {
        view.addSubview(headerLabel)
        view.addSubview(nameLabel)
        view.addSubview(nameTextField)
        view.addSubview(genderSelectionButton)
        view.addSubview(sexualitySelectionButton)
        view.addSubview(lookingForSelectionButton)
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        genderSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        sexualitySelectionButton.translatesAutoresizingMaskIntoConstraints = false
        lookingForSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            
            nameLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            
            genderSelectionButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 25),
            genderSelectionButton.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            genderSelectionButton.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            genderSelectionButton.heightAnchor.constraint(equalToConstant: 70),
            
            sexualitySelectionButton.topAnchor.constraint(equalTo: genderSelectionButton.bottomAnchor, constant: 25),
            sexualitySelectionButton.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            sexualitySelectionButton.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            sexualitySelectionButton.heightAnchor.constraint(equalToConstant: 70),
            
            lookingForSelectionButton.topAnchor.constraint(equalTo: sexualitySelectionButton.bottomAnchor, constant: 25),
            lookingForSelectionButton.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            lookingForSelectionButton.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            lookingForSelectionButton.heightAnchor.constraint(equalToConstant: 70),
        ])
    }
}
