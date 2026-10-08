//
//  SceneDelegate.swift
//  MarketApp
//
//  Created by Amin faruq on 06/10/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let rootViewController = AppComposer.makeRootViewController()
        
        window.rootViewController = rootViewController
        self.window = window
        window.makeKeyAndVisible()
    }

}

