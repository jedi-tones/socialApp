//
//  LoginViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 02.07.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SwiftUI
import FirebaseAuth
import Lottie

class LoginViewController: UIViewController {
    
    private let signInLogo = AnimationCustomView(name: "logo_eye", loopMode: .loop, contentMode: .scaleAspectFill)
    
    private let loginButton = RoundButton(newBackgroundColor: .myLabelColor(),
                                  newBorderColor: .myLabelColor(),
                                  title: "Далее",
                                  titleColor: .myWhiteColor())

    private let backButton = UIButton(newBackgroundColor: nil,
                              title: "Выбрать другой метод входа",
                              titleColor: .myGrayColor(),
                              font: .avenirRegular(size: 16))
    
    private let emailTextField = OneLineTextField(isSecureText: false,
                                          tag: 1)
    private let passwordTextField = OneLineTextField(isSecureText: true,
                                             tag: 2,
                                             opacity: 0,
                                             isEnable: false)
    
    private let emailLabel = UILabel(labelText: "Напиши свою почту",
                             textFont: .avenirRegular(size: 16),
                             textColor: .myGrayColor())
    let correctEmailLabel = UILabel(labelText: "Неправильно введена почта",
                                    textFont: .avenirRegular(size: 16),
                                    textColor: .mySecondSatColor(),
                                    opacity: 0)
    private let passwordLabel = UILabel(labelText: "Пароль",
                                textFont: .avenirRegular(size: 16),
                                textColor: .myGrayColor(),
                                opacity: 0)
    
    weak var navigationDelegate: NavigationDelegate?
    
    init(navigationDelegate: NavigationDelegate?){
        self.navigationDelegate = navigationDelegate
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
extension LoginViewController {
    
    private func setupVC() {
        view.backgroundColor = .systemBackground
        navigationItem.backButtonTitle = "Сменить почту"
        
        loginButton.setTitleColor(.myGrayColor(), for: .disabled)
        loginButton.isEnabled = false
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        emailTextField.keyboardType = .emailAddress
        signInLogo.animationView.play()
    }
    
    private func setupButtonAction() {
        loginButton.addTarget(self, action: #selector(loginButtonPressed), for: .touchUpInside)
        emailTextField.addTarget(self, action: #selector(emailEnterComplite), for: .editingDidEnd)
        backButton.addTarget(self, action: #selector(backButtonTupped), for: .touchUpInside)
    }
}

extension LoginViewController {
    //MARK:  emailEnterComplite
    @objc private func emailEnterComplite() {
        
        guard let email = emailTextField.text, email != "" else { return }
        
        guard Validators.shared.isEmail(email: email) else {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.loginButton.isEnabled = false
                self?.correctEmailLabel.layer.opacity = 1
                self?.passwordTextField.text = ""
                self?.passwordTextField.layer.opacity = 0
                self?.passwordTextField.isHidden = true
                self?.passwordLabel.layer.opacity = 0
                
            }
            return
        }
        //check current email in Firebase auth, than show password textField
        AuthService.shared.isEmailAlreadyRegister(email: email) {[weak self] result in
            switch result {
            
            case .success(let isRegister):
                if isRegister {
                    self?.passwordTextField.isEnabled = true
                    UIView.animate(withDuration: 0.3) {
                        self?.correctEmailLabel.layer.opacity = 0
                        self?.passwordTextField.layer.opacity = 1
                        self?.passwordTextField.isHidden = false
                        self?.passwordLabel.layer.opacity = 1
                        self?.resignFirstResponder()
                        self?.loginButton.isEnabled = true
                    }
                } else {
                    self?.passwordTextField.isEnabled = false
                    UIView.animate(withDuration: 0.3) {
                        self?.correctEmailLabel.layer.opacity = 0
                        self?.passwordTextField.text = ""
                        self?.passwordTextField.layer.opacity = 0
                        self?.passwordTextField.isHidden = true
                        self?.passwordLabel.layer.opacity = 0
                    }
                    self?.loginButton.isEnabled = true
                }
            case .failure(_):
                self?.showAlert(title: "Проблемы с подключением", text: "Повтори чуть позже", buttonText: "OK")
            }
        }
    }
    
    //MARK: - loginButtonPressed
    @objc private func loginButtonPressed() {
        
        switch passwordTextField.isEnabled {
        case true:
            AuthService.shared.signIn(email: emailTextField.text,
                                      password: passwordTextField.text) {[weak self] result in
                switch result {
                case .success( let user):
                    
                    //if correct login user, than close LoginVC and check setProfile info
                    FirestoreService.shared.getUserData(userID: user.email! ) { result in
                        switch result {
                        
                        case .success(let mPeople):
                            if mPeople.userImage == "" {
                                self?.dismiss(animated: true, completion: nil)
                                self?.navigationDelegate?.toCompliteRegistration(userID: mPeople.senderId)
                            } else {
                                let mainVC = MainTabBarController(currentUser: mPeople,
                                                                  isNewLogin: true)
                                mainVC.modalPresentationStyle = .fullScreen
                                self?.present(mainVC, animated: true, completion: nil)
                            }
                            
                        //error of getUserData
                        case .failure(let error):
                            PopUpService.shared.showInfo(text: "Ошибка загрузки профиля: \(error.localizedDescription)")
                        }
                    }
                //error of logIn
                case .failure( _):
                    self?.showAlert(title: "Ошибка входа",
                                    text: "Некорректная комбинация email/пароль",
                                    buttonText: "Попробую еще")
                }
            }
        //if passwordTextField is disable go to RegisterVC
        default:
            guard let delegate = navigationDelegate else { fatalError("Can't get navigationDelegate")}
            let registerEmailVC = RegisterEmailViewController(email: emailTextField.text, navigationDelegate: delegate)
            navigationController?.pushViewController(registerEmailVC, animated: true)
        }
    }
    
    @objc private func backButtonTupped() {
        view.addCustomTransition(type: .fade)
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == emailTextField {
            textField.selectAll(nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            if Validators.shared.isEmail(email: emailTextField.text ?? "") {
                emailEnterComplite()
            }
        }
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField, nextField.isEnabled {
            
            if Validators.shared.isEmail(email: emailTextField.text ?? "") {
                nextField.becomeFirstResponder()
            } else {
                textField.becomeFirstResponder()
                textField.selectAll(nil)
                emailEnterComplite()
                return false
            }
            
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
}

//MARK:  showAlert
extension LoginViewController {
    
    private func showAlert(title: String, text: String, buttonText: String) {
        
        let alert = UIAlertController(title: title,
                                      text: text,
                                      buttonText: buttonText,
                                      style: .alert)
        
        alert.setMyLightStyle()
        present(alert, animated: true, completion: nil)
    }
}

//MARK touchBegan
extension LoginViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

//MARK: - setupConstraints

extension LoginViewController {
    private func setupConstraints() {
        
        view.addSubview(signInLogo)
        view.addSubview(loginButton)
        view.addSubview(correctEmailLabel)
        view.addSubview(emailLabel)
        view.addSubview(passwordLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(backButton)
        
        signInLogo.anchor(leading: view.leadingAnchor,
                          trailing: view.trailingAnchor,
                          top: view.safeAreaLayoutGuide.topAnchor,
                          bottom: nil,
                          height: signInLogo.widthAnchor,
                          multiplier: .init(width: 0, height: 0.25),
                          padding: .init(top: 25, left: 25, bottom: 0, right: 25))
        
        emailTextField.anchor(leading: view.leadingAnchor,
                              trailing: view.trailingAnchor,
                              top: signInLogo.bottomAnchor,
                              bottom: nil,
                              padding: .init(top: 60, left: 25, bottom: 0, right: 25))
        
        emailLabel.anchor(leading: view.leadingAnchor,
                          trailing: view.trailingAnchor,
                          top: nil,
                          bottom: emailTextField.topAnchor,
                          padding: .init(top: 15, left: 25, bottom: 0, right: 25))
        
        correctEmailLabel.anchor(leading: view.leadingAnchor,
                                 trailing: view.trailingAnchor,
                                 top: emailTextField.bottomAnchor,
                                 bottom: nil,
                                 padding: .init(top: 5, left: 25, bottom: 0, right: 25))
        
        passwordTextField.anchor(leading: view.leadingAnchor,
                                 trailing: view.trailingAnchor,
                                 top: correctEmailLabel.topAnchor,
                                 bottom: nil,
                                 padding: .init(top: 40, left: 25, bottom: 0, right: 25))
        
        passwordLabel.anchor(leading: view.leadingAnchor,
                             trailing: view.trailingAnchor,
                             top: nil,
                             bottom: passwordTextField.topAnchor,
                             padding: .init(top: 15, left: 25, bottom: 0, right: 25))
        
        backButton.anchor(leading: loginButton.leadingAnchor,
                          trailing: loginButton.trailingAnchor,
                          top: nil,
                          bottom: loginButton.topAnchor,
                          height: backButton.widthAnchor,
                          multiplier: .init(width: 0, height: 1.0/7.28),
                          padding: .init(top: 0, left: 0, bottom: 10, right: 0))
        
        loginButton.anchor(leading: view.leadingAnchor,
                           trailing: view.trailingAnchor,
                           top: nil,
                           bottom: view.safeAreaLayoutGuide.bottomAnchor,
                           height: loginButton.widthAnchor,
                           multiplier: .init(width: 0, height: 1.0/7.28),
                           padding: .init(top: 0, left: 25, bottom: 25, right: 25))
    }
}
