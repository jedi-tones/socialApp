//
//  SignUpViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 28.06.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SwiftUI
import FirebaseAuth

class RegisterEmailViewController: UIViewController {
    
    private let loginLabel = UILabel(labelText: "Проверь mail почту",
                             textFont: .avenirBold(size: 16),
                             opacity: 0,
                             linesCount: 0)
    private let emailInstructionLabel = UILabel(labelText: "Пройди по ссылке в письме для активации",
                                        textFont: .avenirRegular(size: 16),
                                        textColor: .myGrayColor(),
                                        opacity:  0,
                                        linesCount: 0)
    private let emailLabelHeader = UILabel(labelText: "Твоя почта:",
                             textFont: .avenirBold(size: 24),
                             textColor: .myLabelColor(),
                             opacity: 1)
    
    private let emailLabel = UILabel(labelText: "mail@jedi-tones.art",
                             textFont: .avenirRegular(size: 16),
                             textColor: .myGrayColor(),
                             opacity: 1)
    
    private let passwordLabel = UILabel(labelText: "Придумай к ней пароль",
                                textFont: .avenirRegular(size: 16),
                                textColor: .myGrayColor(),
                                opacity: 1)
    private let confirmPasswordLabel = UILabel(labelText: "Повтори пароль",
                                       textFont: .avenirRegular(size: 16),
                                       textColor: .myGrayColor(),
                                       opacity: 1)
    
    private let passwordTextField = OneLineTextField(isSecureText: true,
                                             tag: 1,
                                             opacity: 1,
                                             isEnable: true,
                                             placeHoledText: "Пароль")
    private let confirmPasswordTextField = OneLineTextField(isSecureText: true,
                                                    tag: 2,
                                                    opacity: 1,
                                                    isEnable: true,
                                                    placeHoledText: "Пароль")
    
    private let signUpButton = RoundButton(newBackgroundColor: .myLabelColor(),
                                newBorderColor: .myLabelColor(),
                                title: "Продолжить",
                                titleColor: .myWhiteColor())
    
    private let checkMailButton = RoundButton(newBackgroundColor: .myLabelColor(),
                                   newBorderColor: .myLabelColor(),
                                   title: "Проверить активацию",
                                   titleColor: .myWhiteColor(),
                                   isHidden: true)

    private var email:String?
    private weak var navigationDelegate: NavigationDelegate?
    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    
    init(email: String?, currentPeopleDelegate: CurrentPeopleDataDelegate?, navigationDelegate: NavigationDelegate?){
        self.currentPeopleDelegate = currentPeopleDelegate
        self.navigationDelegate = navigationDelegate
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVC()
        setupConstraints()
        setupButtonAction()
    }    
}

//MARK: - setupVC
extension RegisterEmailViewController {
    
    private func setupVC() {
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.isHidden = false        
       
        if let email = email {
            loginLabel.text = "Проверь \(email) почту, пройди по ссылке в письме для активации"
            emailLabel.text = email
        }
        
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }

    private func setupButtonAction() {
        signUpButton.addTarget(self, action: #selector(signUpButtonPressed), for: .touchUpInside)
    }
}

//MARK: - objc action
extension RegisterEmailViewController {
    
    @objc func signUpButtonPressed() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in RegistrationEmailVC")}
        //need check activation mail before next VC
        AuthService.shared.register(
            email: email,
            password: passwordTextField.text,
            confirmPassword: confirmPasswordTextField.text
        ) {[weak self] result in
            switch result {
            case .success(let user):
                guard let email = user.email else { fatalError("cant get email")}
                //if user create in auth, then create current user in cloud Firestore
                FirestoreService.shared.saveBaseProfile(id: email,
                                                        email: email,
                                                        authType: .email) { result in
                    switch result {
                    case .success(_):
                        //after save base profile in Firestore, close and show complite registration VC
                        let newVC = DateOfBirthViewController(currentPeopleDelegate: currentPeopleDelegate)
                        self?.navigationController?.setViewControllers([newVC], animated: true)
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                }
                
            case .failure(let error):
                let myError = error.localizedDescription
                self?.showAlert(title: "Ошибка",
                                text: myError,
                                buttonText: "Понятно")
                self?.signUpButton.isEnabled = true
            }
        }
    }
}

//MARK: - UITextFieldDelegate
extension RegisterEmailViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField, nextField.isEnabled {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
}
//MARK: - showAlert
extension RegisterEmailViewController {
    
    private func showAlert(title: String,
                           text: String,
                           buttonText: String,
                           complition: @escaping ()-> Void = { }) {
        
        let alert = UIAlertController(title: title,
                                      text: text,
                                      buttonText: buttonText,
                                      style: .alert,
                                      buttonHandler: complition)
        
        present(alert, animated: true, completion: nil)
        
        alert.setMyLightStyle()
    }
}

//MARK touchBegan
extension RegisterEmailViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
}

//MARK: - setupConstraints
extension RegisterEmailViewController {
    private func setupConstraints() {
        
        emailInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        checkMailButton.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        emailLabelHeader.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        

        view.addSubview(emailLabelHeader)
        view.addSubview(emailLabel)
        view.addSubview(emailInstructionLabel)
        view.addSubview(checkMailButton)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(loginLabel)
        view.addSubview(passwordLabel)
        view.addSubview(confirmPasswordLabel)
        view.addSubview(signUpButton)
        
        NSLayoutConstraint.activate([
            
            emailLabelHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            emailLabelHeader.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            emailLabelHeader.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            emailLabel.topAnchor.constraint(equalTo: emailLabelHeader.bottomAnchor, constant: 10),
            emailLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            emailLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            passwordTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 68),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            passwordLabel.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -5),
            passwordLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            passwordLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 68),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            confirmPasswordLabel.bottomAnchor.constraint(equalTo: confirmPasswordTextField.topAnchor, constant: -5),
            confirmPasswordLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            confirmPasswordLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            loginLabel.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 25),
            loginLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            loginLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            emailInstructionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 5),
            emailInstructionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            emailInstructionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            checkMailButton.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 55),
            checkMailButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            checkMailButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            checkMailButton.heightAnchor.constraint(equalTo: checkMailButton.widthAnchor, multiplier: 1.0/7.28),
                    
            signUpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            signUpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            signUpButton.heightAnchor.constraint(equalTo: signUpButton.widthAnchor, multiplier: 1.0/7.28)
        ])
    }
}
