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

class SetProfileViewController: UIViewController {
    
    let profileImage = ProfileImageView()
    let nameLabel = UILabel(labelText: "Называй меня:",
                            textFont: .systemFont(ofSize: 16, weight: .bold))
    let aboutLabel = UILabel(labelText: "Мои желания на сегодня:",
                             textFont: .systemFont(ofSize: 16, weight: .bold))
    let sexLabel = UILabel(labelText: "Я",
                           textFont: .systemFont(ofSize: 16, weight: .regular))
    let wantLabel = UILabel(labelText: "ищу",
                            textFont: .systemFont(ofSize: 16, weight: .regular))
    let nameTextField = OneLineTextField(isSecureText: false,
                                         tag: 1,
                                         placeHoledText: "Ты можешь быть кем угодно...")
    let advertTextView = OneLineTextView(text: "Для просмотра обьявлений других пользователей, расскажи о своих желаниях...",
                                          isEditable: true)

    let sexButton = UIButton(newBackgroundColor: nil,
                             borderWidth: 0,
                             title: Sex.man.rawValue,
                             titleColor: .myPurpleColor())
    let wantButton = UIButton(newBackgroundColor: nil,
                              borderWidth: 0,
                              title: Want.woman.rawValue,
                              titleColor: .myPurpleColor())
    let goButton = UIButton(newBackgroundColor: .label,
                            newBorderColor: .label,
                            title: "Начнем!",
                            titleColor: .systemBackground)
    
    var delegate: AuthNavigationDelegate?
    
    private var currentPeople: MPeople?
    private var currentUser: User?
    
    init(currentUser: User) {
        self.currentUser = currentUser
        super.init(nibName: nil, bundle: nil)
    }
    
    //init for SwiftUI canvas
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        setupConstraints()
        setupButtonAction()
        getPeopleData()
        setupVC()
        
    }
    
    private func setupVC() {
        view.backgroundColor = .systemBackground
        advertTextView.delegate = self
        nameTextField.delegate = self
    }
}
//MARK: - setupNavigationController
extension SetProfileViewController {
    private func setupNavigationController(){
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.backgroundColor = .systemBackground
        navigationItem.title = "Профиль"
        let exitItem = UIBarButtonItem(title: "Выход", style: .plain, target: self, action: #selector(signOut))
        exitItem.tintColor = .label
        navigationItem.rightBarButtonItem = exitItem
        
        
    }
}

//MARK: - getPeopleData
extension SetProfileViewController {
    
    private func getPeopleData() {
        
        guard let user = currentUser else { return }
        FirestoreService.shared.getUserData(user: user) {[weak self] result in
            switch result {
                
            case .success(let mPeople):
                
                self?.currentPeople = mPeople
                self?.setPeopleData()
                
            case .failure(_):
                print("Cant get user data")
                return
            }
        }
        
    }
}

//MARK: - setPeopleData
extension SetProfileViewController {
    
    private func setPeopleData() {
        
        guard let people = currentPeople else { return }
        
        StorageService.shared.getImage(link: people.userImage) {[weak self] result in
            switch result {

            case .success(let image):
                self?.profileImage.profileImage.image = image
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        
        nameTextField.text = people.userName
        advertTextView.text = people.advert
        advertTextView.textColor = .label
        sexButton.isEnabled = false
        sexButton.setTitleColor(.label, for: .disabled)
        
        if people.sex != "" {
            sexButton.setTitle(people.sex, for: .normal)
        }
        
        if people.search != "" {
            wantButton.setTitle(people.search, for: .normal)
        }
    }
}
//MARK: - setupButtonAction
extension SetProfileViewController {
    
    private func setupButtonAction() {
        
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        profileImage.plusButton.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)
        sexButton.addTarget(self, action: #selector(touchSexButton), for: .touchUpInside)
        wantButton.addTarget(self, action: #selector(touchWantButton), for: .touchUpInside)
        
    }
}

//MARK: - objc action
extension SetProfileViewController {
    
    @objc func signOut() {
        signOutAlert()
    }
    
    @objc func touchSexButton() {
        switch sexButton.titleLabel?.text {
        case Sex.man.rawValue:
            sexButton.setTitle(Sex.woman.rawValue, for: .normal)
            wantButton.setTitle(Want.man.rawValue, for: .normal)
        default:
            sexButton.setTitle(Sex.man.rawValue, for: .normal)
            wantButton.setTitle(Want.woman.rawValue, for: .normal)
        }
    }
    
    @objc func touchWantButton() {
        switch wantButton.titleLabel?.text {
        case Want.man.rawValue:
            wantButton.setTitle(Want.woman.rawValue, for: .normal)
        default:
            wantButton.setTitle(Want.man.rawValue, for: .normal)
        }
    }
    
    @objc func choosePhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        choosePhotoAlert {[weak self] sourceType in
            guard let type = sourceType else { return }
            imagePicker.sourceType = type
            self?.present(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    @objc func goButtonPressed() {
        guard let sex = sexButton.titleLabel?.text else { return }
        guard let search = wantButton.titleLabel?.text else { return }
        guard let user = currentUser else { return }
        guard let email = user.email else { return }
        
        print(user.uid)
        
        FirestoreService.shared.saveProfile(
            id: user.uid,
            email: email,
            username: nameTextField.text,
            avatarImage: profileImage.profileImage.image,
            advert: advertTextView.text,
            search: search,
            sex: sex
        ) {[weak self] result in
            
            switch result {
                
            case .success(let mPeople):
                self?.currentPeople = mPeople
                self?.sexButton.isEnabled = false
                self?.sexButton.setTitleColor(.label, for: .disabled)
            case .failure(let error):
                
                let alert = UIAlertController(title: "Ошибочка",
                                              text: error.localizedDescription,
                                              buttonText: "Понятненько",
                                              style: .actionSheet)
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
}

//MARK: - AlertController

extension SetProfileViewController {
    
    private func signOutAlert() {
        let alert = UIAlertController(title: "Покинуть", message: "Точно прощаешься с нами?", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Выйду, но вернусь", style: .destructive) { _ in
            
            do {
                try Auth.auth().signOut()
                
                let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
                keyWindow?.rootViewController = AuthViewController()
            } catch {
                print( "SignOut error: \(error.localizedDescription)")
            }
            
        }
        let cancelAction = UIAlertAction(title: "Продолжу общение", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }


private func choosePhotoAlert(complition: @escaping (_ sourceType:UIImagePickerController.SourceType?) -> Void) {
    
    let photoAlert = UIAlertController(title: "Фоточка",
                                       message: "Если сделать новую, остальным отобразится, что твое она настоящяя",
                                       preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Новая, открыть камеру",
                                     style: .default) { _ in
                                        
                                        complition(UIImagePickerController.SourceType.camera)
    }
    let libraryAction = UIAlertAction(title: "Выбрать из галереи",
                                      style: .default) { _ in
                                        complition(UIImagePickerController.SourceType.photoLibrary)
    }
    let cancelAction = UIAlertAction(title: "Отмена",
                                     style: .destructive) { _ in
                                        complition(nil)
    }
    photoAlert.addAction(cameraAction)
    photoAlert.addAction(libraryAction)
    photoAlert.addAction(cancelAction)
    
    present(photoAlert, animated: true, completion: nil)
    }
}

extension SetProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           
           textField.resignFirstResponder()
           return false
       }
    
}
//MARK: - UITextViewDelegate
extension SetProfileViewController:UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Для просмотра обьявлений других пользователей, расскажи о своих желаниях..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Для просмотра обьявлений других пользователей, расскажи о своих желаниях..."
            textView.textColor = .lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxSymbols = 120
        let existingLines = textView.text.components(separatedBy: CharacterSet.newlines)
        let newLines = text.components(separatedBy: CharacterSet.newlines)
        let linesAfterChange = existingLines.count + newLines.count - 1
        if(text == "\n") {
            if linesAfterChange <= textView.textContainer.maximumNumberOfLines {
                return true
            } else {
                textView.resignFirstResponder()
                return false
            }
            
        }
        
        let newLine = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let characterCount = newLine.count
        if characterCount <= maxSymbols {
            return true
        } else {
            textView.resignFirstResponder()
            return false
        }
        
    }
}

//MARK: - UIImagePickerControllerDelegate

extension SetProfileViewController:UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        profileImage.profileImage.image = image
    }
}

//MARK: - setupConstraints
extension SetProfileViewController {
    
    private func setupConstraints() {
        
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        sexLabel.translatesAutoresizingMaskIntoConstraints = false
        wantLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        advertTextView.translatesAutoresizingMaskIntoConstraints = false
        sexButton.translatesAutoresizingMaskIntoConstraints = false
        wantButton.translatesAutoresizingMaskIntoConstraints = false
        goButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileImage)
        view.addSubview(nameLabel)
        view.addSubview(aboutLabel)
        view.addSubview(sexLabel)
        view.addSubview(wantLabel)
        view.addSubview(nameTextField)
        view.addSubview(advertTextView)
        view.addSubview(sexButton)
        view.addSubview(wantButton)
        view.addSubview(goButton)
        
        NSLayoutConstraint.activate([
            
            profileImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            profileImage.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            profileImage.heightAnchor.constraint(equalTo: profileImage.widthAnchor, multiplier: 1/1),
            
            nameTextField.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 45),
            nameTextField.heightAnchor.constraint(equalToConstant: 25),
            nameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            nameTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            nameLabel.bottomAnchor.constraint(equalTo: nameTextField.topAnchor, constant: -5),
            nameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            advertTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 45),
            advertTextView.heightAnchor.constraint(equalToConstant: 100),
            advertTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            advertTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            aboutLabel.bottomAnchor.constraint(equalTo: advertTextView.topAnchor, constant: 0),
            aboutLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            aboutLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            
            sexLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            sexLabel.bottomAnchor.constraint(equalTo: goButton.topAnchor, constant: -25),
            
            sexButton.leadingAnchor.constraint(equalTo: sexLabel.trailingAnchor, constant: 5),
            sexButton.bottomAnchor.constraint(equalTo: goButton.topAnchor, constant: -25),
            sexButton.heightAnchor.constraint(equalToConstant: 22),
            
            wantLabel.leadingAnchor.constraint(equalTo: sexButton.trailingAnchor, constant: 5),
            wantLabel.bottomAnchor.constraint(equalTo: goButton.topAnchor, constant: -25),
            
            wantButton.leadingAnchor.constraint(equalTo: wantLabel.trailingAnchor, constant: 5),
            wantButton.bottomAnchor.constraint(equalTo: goButton.topAnchor, constant: -25),
            wantButton.heightAnchor.constraint(equalToConstant: 22),
            
            
            goButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            goButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            goButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            goButton.heightAnchor.constraint(equalTo: goButton.widthAnchor, multiplier: 1.0/7.28),
        ])
    }
    
}

//MARK: - SwiftUI
struct SetupProfileViewControllerProvider: PreviewProvider {
    
    static var previews: some View {
        ContenerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContenerView: UIViewControllerRepresentable {
        
        func makeUIViewController(context: Context) -> SetProfileViewController {
            
            return SetProfileViewController()
        }
        
        func updateUIViewController(_ uiViewController: SetProfileViewController, context: Context) {
            
        }
    }
}