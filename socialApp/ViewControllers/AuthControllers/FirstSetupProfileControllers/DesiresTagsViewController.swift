//
//  DesiresTagsViewControllee.swift
//  socialApp
//
//  Created by Денис Щиголев on 27.11.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

class DesiresTagsViewController: UIViewController {

    private weak var currentPeopleDelegate: CurrentPeopleDataDelegate?
    private let tagsView = TagsSetupView(unselectTags: MDefaultsDesires.getSortedDesires(),
                                         tagsHeader: "Выбранные желания",
                                         viewHeader: MLabels.desiresTagsHeader.rawValue)
   
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tagsView.update()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tagsView.updateScrollView()
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

//MARK: obcj
extension DesiresTagsViewController {
    
    @objc private func saveButtonTapped() {
        guard let currentPeopleDelegate = currentPeopleDelegate else { fatalError("currentPeopleDelegate is nil in DesiresTagsVC")}
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        let selecetedDiseresTags = tagsView.getSelectedTags()
        
        
        FirestoreService.shared.saveDesires(id: currentPeopleDelegate.currentPeople.senderId,
                                            desires: selecetedDiseresTags) {[weak self] result in
            switch result {
            
            case .success(_):
                let nextViewController = InterestsSelectionViewController(currentPeopleDelegate: currentPeopleDelegate)
                self?.navigationController?.setViewControllers([nextViewController], animated: true)
            case .failure(let error):
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                PopUpService.shared.showInfo(text: "Ошибка: \(error)")
            }
        }
    }
}


//MARK: setupConstraints
extension DesiresTagsViewController {
    private func setupConstraints() {
        view.addSubview(tagsView)
       
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            tagsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tagsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tagsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tagsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
        ])
    }
}
