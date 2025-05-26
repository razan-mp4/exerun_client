//
//  SceneDelegate.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/1/2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Keychain token check
        let token = KeychainManager.shared.loadToken()
        let storyboardName = (token != nil && !token!.isEmpty) ? "Main" : "Auth"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else {
            fatalError("Could not instantiate initial view controller from \(storyboardName) storyboard")
        }
        window?.rootViewController = initialVC
        window?.makeKeyAndVisible()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        WorkoutSyncManager.shared.kick()
        AccountSyncManager.shared.kick()
        GymPlanSyncManager.shared.kick()
    }

}
