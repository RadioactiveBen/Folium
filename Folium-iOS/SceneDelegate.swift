//
//  SceneDelegate.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 2/4/2024.
//

import Foundation
import UIKit

public struct Utsname {
    public init() {}

    private var systemInfo: utsname {
        var result: utsname = utsname()
        uname(&result)
        return result
    }
    public var sysname: String {
        let mirror = Mirror(reflecting: self.systemInfo.sysname)
        return self._string(from: mirror)
    }
    public var nodename: String {
        let mirror = Mirror(reflecting: self.systemInfo.nodename)
        return self._string(from: mirror)
    }
    public var release: String {
        let mirror = Mirror(reflecting: self.systemInfo.release)
        return self._string(from: mirror)
    }
    public var version: String {
        let mirror = Mirror(reflecting: self.systemInfo.version)
        return self._string(from: mirror)
    }
    public var machine: String {
        let mirror = Mirror(reflecting: self.systemInfo.machine)
        return self._string(from: mirror)
    }

    private func _string(from mirror: Mirror) -> String {
        var result = ""
        for child in mirror.children {
            if let value = child.value as? Int8 , value != 0 {
                result.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        return result
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        // TODO: print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
        // TODO: UserDefaults.standard.removeObject(forKey: "finishedOnboarding")
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        window = .init(windowScene: windowScene)
        guard let window else {
            return
        }
        
        if UserDefaults.standard.bool(forKey: "finishedOnboarding") {
            Task {
                try DirectoriesManager.shared.createMissingDirectoriesInDocumentsDirectory()
            
                let cores = try LibraryManager.shared.library()
            
                window.rootViewController = UINavigationController(rootViewController: LibraryController(collectionViewLayout: Layouts.shared.library(cores), cores: cores))
            }
        } else {
            window.rootViewController = OBGetStartedController(step: .init(systemNames: [
                "arcade.stick.console", "arcade.stick.console.fill", "gamecontroller", "gamecontroller.fill", "circle.grid.cross",
                "circle.grid.cross.fill", "dpad", "dpad.fill", "circle.circle", "circle.circle.fill", "square.circle", "square.circle.fill",
                "triangle.circle", "triangle.circle.fill", "xmark.circle", "xmark.circle.fill", "a.circle", "a.circle.fill", "b.circle",
                "b.circle.fill", "x.circle", "x.circle.fill", "y.circle", "y.circle.fill"
            ], text: "Folium", secondaryText: "Beautifully designed, high performing multi-system emulation in the palm of your hands",
                                                                           buttonText: "Get Started", buttonAction: { _ in
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                if let enumerator = FileManager.default.enumerator(at: documentsDirectory,
                                                                   includingPropertiesForKeys: [.isRegularFileKey],
                                                                   options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                    do {
                        try enumerator.forEach { element in
                            switch element {
                            case let url as URL:
                                let attributes = try url.resourceValues(forKeys: [.isRegularFileKey])
                                if let isRegularFile = attributes.isRegularFile, isRegularFile {
                                    if url.lastPathComponent.lowercased() == "config.ini" {
                                        try FileManager.default.removeItem(at: url)
                                    }
                                }
                            default:
                                break
                            }
                        }
                    } catch { }
                }
                
                let optionalFilesController = self.optionalFilesController()
                optionalFilesController.modalPresentationStyle = .fullScreen
                UIApplication.topViewController()?.present(optionalFilesController, animated: true)
            }, buttonColor: nil))
        }
        window.tintColor = .systemGreen
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NotificationCenter.default.post(name: .init("sceneDidChange"), object: nil, userInfo: [
            "state" : 1
        ])
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        NotificationCenter.default.post(name: .init("sceneDidChange"), object: nil, userInfo: [
            "state" : 0
        ])
    }
    
    
    fileprivate func optionalFilesController() -> OBOptionalFilesController {
        .init(step: .init(systemNames: [
            "doc", "doc.fill", "folder", "folder.fill", "internaldrive", "internaldrive.fill"
        ], text: "Optional Files", secondaryText: "You can see where to place these by tapping on an optional missing file in the Missing Files screen",
                          buttonText: "Continue", buttonAction: { _ in
            let requiredFilesController = self.requiredFilesController()
            requiredFilesController.modalPresentationStyle = .fullScreen
            UIApplication.topViewController()?.present(requiredFilesController, animated: true)
        }, buttonColor: .systemOrange))
    }
    
    fileprivate func requiredFilesController() -> OBRequiredFilesController {
        .init(step: .init(systemNames: [
            "doc", "doc.fill", "folder", "folder.fill", "internaldrive", "internaldrive.fill"
        ], text: "Required Files", secondaryText: "You can see where to place these by tapping on a required missing file in the Missing Files screen",
                          buttonText: "Continue", buttonAction: { _ in
            let gameFilesController = self.gameFilesController()
            gameFilesController.modalPresentationStyle = .fullScreen
            UIApplication.topViewController()?.present(gameFilesController, animated: true)
        }, buttonColor: .systemRed))
    }
    
    fileprivate func gameFilesController() -> OBGamesFilesController {
        .init(step: .init(systemNames: [
            "arcade.stick.console", "arcade.stick.console.fill", "gamecontroller", "gamecontroller.fill", "circle.grid.cross",
            "circle.grid.cross.fill", "dpad", "dpad.fill", "circle.circle", "circle.circle.fill", "square.circle", "square.circle.fill",
            "triangle.circle", "triangle.circle.fill", "xmark.circle", "xmark.circle.fill", "a.circle", "a.circle.fill", "b.circle",
            "b.circle.fill", "x.circle", "x.circle.fill", "y.circle", "y.circle.fill"
        ], text: "Game Files", secondaryText: "You can place these anywhere within their respective cores roms directory",
                          buttonText: "Continue", buttonAction: { _ in
            let discordController = self.discordController()
            discordController.modalPresentationStyle = .fullScreen
            UIApplication.topViewController()?.present(discordController, animated: true)
        }, buttonColor: nil))
    }
    
    fileprivate func discordController() -> OBDiscordController {
        .init(step: .init(systemNames: [
            "mic", "mic.fill", "message", "message.fill", "bubble", "bubble.fill", "photo.on.rectangle", "photo.on.rectangle.fill", "video", "video.fill", "play",
            "play.fill", "pause", "pause.fill", "stop", "stop.fill"
        ], text: "Discord", secondaryText: "Join the Folium Discord server to get and give help, browse and share gameplay videos and more\n\nhttps://folium.emuplace.app/discord",
                          buttonText: "Open Library", buttonAction: { _ in
            UserDefaults.standard.setValue(true, forKey: "finishedOnboarding")
            
            Task {
                try DirectoriesManager.shared.createMissingDirectoriesInDocumentsDirectory()
            
                let cores = try LibraryManager.shared.library()
            
                let libraryController = UINavigationController(rootViewController: LibraryController(collectionViewLayout: Layouts.shared.library(cores),
                                                                                                     cores: cores))
                libraryController.modalPresentationStyle = .fullScreen
                UIApplication.topViewController()?.present(libraryController, animated: true)
            }
        }, buttonColor: .systemIndigo))
    }
}
