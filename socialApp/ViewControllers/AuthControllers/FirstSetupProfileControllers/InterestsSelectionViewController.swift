//
//  UnterestsSelectionViewController.swift
//  socialApp
//
//  Created by Денис Щиголев on 13.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class InterestsSelectionViewController: UIViewController {
    
    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    private let interestsView = InterestsSelectionView()
    
    init(currentPeopleDelegate: CurrentPeopleDataDelegate?){
        self.currentPeopleDelegate = currentPeopleDelegate
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
    }
}

extension InterestsSelectionViewController {
    @objc private func saveButtonTapped() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in InterestsVC")}
        
        let interestText = interestsView.getInterestsText()
        
        FirestoreService.shared.saveAdvert(id: currentPeopleDelegate.currentPeople.senderId,
                                           advert: interestText) {[weak self] result in
            switch result {
            
            case .success():
                let nextViewController = EditPhotoViewController(currentPeopleDelegate: currentPeopleDelegate,
                                                                 isFirstSetup: true)
                self?.navigationController?.setViewControllers([nextViewController], animated: true)
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension InterestsSelectionViewController {
    
    private func setupConstraints() {
        
        interestsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(interestsView)
        
        NSLayoutConstraint.activate([
            interestsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            interestsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            interestsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interestsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
