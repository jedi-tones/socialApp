//
//  EditPhotoViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 09.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import FirebaseAuth
import SDWebImage

class EditPhotoViewController: UIViewController {
    
    let profileImage = UIImageView(image: nil, contentMode: .scaleAspectFill)
    let scrollView = UIScrollView()
    var collectionView: UICollectionView!
    let addImageButton = UIButton(image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold, scale: .default)) ?? #imageLiteral(resourceName: "plus"))
    let tipsHeader = UILabel(labelText: "Советы", textFont: .avenirRegular(size: 16))
    let tips = UILabel(labelText: MLabels.editPhotoTips.rawValue, textFont: .avenirRegular(size: 16), textColor: .myGrayColor(),linesCount: 0)
    let legalHeader = UILabel(labelText: "Юридическая информация", textFont: .avenirRegular(size: 16))
    let legal = UILabel(labelText: MLabels.editPhotoLegal.rawValue, textFont: .avenirRegular(size: 16), textColor: .myGrayColor(),linesCount: 0)
    var dataSource: UICollectionViewDiffableDataSource<SectionEditPhotos, String>?
    var images: [String] = []
    var currentPeople: MPeople?
    var userID: String
    var isFirstSetup = false
    weak var navigationDelegate: NavigationDelegate?
    
    init (userID: String, isFirstSetup: Bool, navigationDelegate: NavigationDelegate? = nil) {
        self.userID = userID
        self.isFirstSetup = isFirstSetup
        if navigationDelegate != nil {
            self.navigationDelegate = navigationDelegate
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupDataSource()
        setupConstraints()
        setup()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileData()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.updateContentView()
    }
    
    //MARK: setup
    private func setup() {
        addImageButton.backgroundColor = .mySecondButtonColor()
        addImageButton.imageView?.tintColor = .mySecondButtonLabelColor()
        addImageButton.layer.cornerRadius = MDefaultLayer.bigCornerRadius.rawValue
        addImageButton.clipsToBounds = true
        profileImage.layer.cornerRadius = MDefaultLayer.bigCornerRadius.rawValue
        profileImage.clipsToBounds = true
        scrollView.showsVerticalScrollIndicator = false
        
        view.backgroundColor = .myWhiteColor()
        navigationItem.title = "Галерея"
        
        
        addImageButton.addTarget(self, action: #selector(addImageButtonTap), for: .touchUpInside)
        
        if isFirstSetup {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.title = ""
            navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done,
                                                             target: self,
                                                             action: #selector(saveButtonTapped)),
                                             animated: false)
        }
        
    }
    
    //MARK: updateProfileData
    private func updateProfileData() {
        //if first setup Photo -> get from Firebase else get from UserDefaults
        if isFirstSetup {
            FirestoreService.shared.getUserData(userID: userID, complition: {[weak self] result in
                switch result {
                
                case .success(let mPeople):
                    self?.currentPeople = mPeople
                    UserDefaultsService.shared.saveMpeople(people: mPeople)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            })
        } else {
            currentPeople = UserDefaultsService.shared.getMpeople()
        }
        
        if let images = currentPeople?.gallery  {
            updateDataSource(imagesStringURL: images)
        }
        guard let people = currentPeople else { return }
        guard let imageURL = URL(string: people.userImage) else { return }
        profileImage.sd_setImage(with: imageURL, completed: nil)
        updateDataSource(imagesStringURL: people.gallery)
    }
}

//MARK: objc
extension EditPhotoViewController {
    @objc private func addImageButtonTap() {
        let picker = UIImagePickerController()
        picker.delegate = self
        choosePhotoAlert {[weak self] sourceType in
            guard let sourceType = sourceType else { return }
            picker.sourceType = sourceType
            self?.present(picker, animated: true, completion: nil)
        }
    }
    
    @objc private func saveButtonTapped() {
        view.addCustomTransition(type: .fade)
        dismiss(animated: true, completion: { [weak self] in
            if let userID = self?.userID {
                self?.navigationDelegate?.toMainTabBarController(userID: userID)
            }
        })
    }
}


//MARK: - CollectionView
extension EditPhotoViewController {
    
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.frame,
                                          collectionViewLayout: setupLayout())
        collectionView.backgroundColor = .myWhiteColor()
        collectionView.delegate = self
        collectionView.contentSize.height = 10
        collectionView.register(EditPhotoCell.self, forCellWithReuseIdentifier: EditPhotoCell.reuseID)
    }
    
    private func setupPhotosSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.37),
                                               heightDimension: .fractionalWidth(0.37))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 10
    
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 10,
                                                        bottom: 0,
                                                        trailing: 10)
        return section
    }
    
    //MARK: setupLayout
    private func setupLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {[weak self] section, environment -> NSCollectionLayoutSection? in
            guard let section = SectionEditPhotos(rawValue: section) else { fatalError("Unknow section")}
            
            switch section {
            case .photos:
                return self?.setupPhotosSection()
            }
        }
        return layout
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, element) -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EditPhotoCell.reuseID, for: indexPath) as? EditPhotoCell else { fatalError("Cant cast EditPhotoCell") }
                cell.configure(imageStringURL: element) {
                    cell.layoutIfNeeded()
                }
                return cell
            })
    }
    
    //MARK: updateDataSource
    private func updateDataSource(imagesStringURL: [String] = []) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionEditPhotos, String>()
        snapshot.appendSections([.photos])
        snapshot.appendItems(imagesStringURL, toSection: .photos)
        
        dataSource?.apply(snapshot)
    }
}

//MARK: - Alerts
extension EditPhotoViewController {
    private func editGalleryAlert(imageURLString: String, complition:@escaping()->Void) {
        guard let people = UserDefaultsService.shared.getMpeople() else { return }
        let photoAlert = UIAlertController(title: nil,
                                           message: nil,
                                           preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Сделать фото профиля",
                                         style: .default) { _ in
            FirestoreService.shared.updateAvatar(imageURLString: imageURLString,
                                                 currentAvatarURL: people.userImage,
                                                 id: people.senderId) { result in
                switch result {
                case .success(_):
                    complition()
                case .failure(_):
                    break
                }
            }
                                         }
        
        let libraryAction = UIAlertAction(title: "Удалить",
                                          style: .default) { _ in
            FirestoreService.shared.deleteFromGallery(imageURLString: imageURLString,
                                                      id: people.senderId) { result in
                switch result {
                
                case .success(_):
                    complition()
                case .failure(let errror):
                    fatalError(errror.localizedDescription)
                }
            }
                                          }
        let cancelAction = UIAlertAction(title: "Отмена",
                                         style: .default) { _ in
            
        }
        
        photoAlert.setMyStyle()
        photoAlert.addAction(cameraAction)
        photoAlert.addAction(libraryAction)
        photoAlert.addAction(cancelAction)
        
        present(photoAlert, animated: true, completion: nil)
    }
    
    //MARK:  choosePhotoAlert
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

//MARK: collectionViewDelegate
extension EditPhotoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let stringImageURL = dataSource?.itemIdentifier(for: indexPath) else { return }
        
        editGalleryAlert(imageURLString: stringImageURL) { [weak self] in
            
            self?.updateProfileData()
        }
    }
}

//MARK:  UIImagePickerControllerDelegate
extension EditPhotoViewController:UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        guard var people = currentPeople else { return }
        //if user don't have profile image, set new to profile
        if people.userImage == "" {
            FirestoreService.shared.saveAvatar(image: image, id: people.senderId) {[weak self] result in
                switch result {
                case .success(_):
                    
                    self?.currentPeople = UserDefaultsService.shared.getMpeople()
                    self?.profileImage.image = image
                    
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
            //if user have profile image, save to gallery
        } else {
            FirestoreService.shared.saveImageToGallery(image: image, id: people.senderId) {[weak self] result in
                switch result {
                
                case .success(let imageURLString):
                    people.gallery.append(imageURLString)
                    self?.currentPeople = people
                    UserDefaultsService.shared.saveMpeople(people: people)
                    self?.updateDataSource(imagesStringURL: people.gallery)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
}

//MARK: setupConstraints
extension EditPhotoViewController {
    private func setupConstraints() {
        view.addSubview(scrollView)
        scrollView.addSubview(profileImage)
        scrollView.addSubview(addImageButton)
        scrollView.addSubview(collectionView)
        scrollView.addSubview(tipsHeader)
        scrollView.addSubview(tips)
        scrollView.addSubview(legalHeader)
        scrollView.addSubview(legal)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        tipsHeader.translatesAutoresizingMaskIntoConstraints = false
        tips.translatesAutoresizingMaskIntoConstraints = false
        legalHeader.translatesAutoresizingMaskIntoConstraints = false
        legal.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            profileImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            profileImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            profileImage.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 25),
            profileImage.heightAnchor.constraint(equalTo: profileImage.widthAnchor),
            
            addImageButton.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            addImageButton.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 10),
            addImageButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            addImageButton.heightAnchor.constraint(equalTo: addImageButton.widthAnchor),
            
            collectionView.leadingAnchor.constraint(equalTo: addImageButton.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: addImageButton.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: addImageButton.bottomAnchor),
            
            tipsHeader.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            tipsHeader.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor),
            tipsHeader.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 25),
            
            tips.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            tips.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor),
            tips.topAnchor.constraint(equalTo: tipsHeader.bottomAnchor, constant: 10),
            
            legalHeader.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            legalHeader.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor),
            legalHeader.topAnchor.constraint(equalTo: tips.bottomAnchor, constant: 25),
            
            legal.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            legal.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor),
            legal.topAnchor.constraint(equalTo: legalHeader.bottomAnchor, constant: 10),
        ])
    }
}