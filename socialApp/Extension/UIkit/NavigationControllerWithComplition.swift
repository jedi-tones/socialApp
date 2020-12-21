//
//  NavigationControllerWithComplition.swift
//  socialApp
//
//  Created by Денис Щиголев on 21.12.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit

public class NavigationControllerWithComplition: UINavigationController, UINavigationControllerDelegate
{
    private var completion: (() -> Void)?

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if self.completion != nil {
            DispatchQueue.main.async(execute: {
                self.completion?()
                self.completion = nil
            })
        }
    }

    func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
        self.completion = completion
        super.popToRootViewController(animated: animated)
    }
}
