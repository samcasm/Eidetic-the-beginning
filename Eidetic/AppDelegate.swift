//
//  AppDelegate.swift
//  Eidetic
//
//  Created by user145467 on 11/15/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        let defaults = UserDefaults.standard
        let recentlyAddedTagsArray = defaults.object(forKey:"recentlyAddedTags") as? [String] ?? [String]()
        defaults.set(recentlyAddedTagsArray, forKey: "recentlyAddedTags")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        do {
            try FileManager.default.createDirectory(atPath:FileManager.dataFilesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: FileManager.tagsFileURL.path, isDirectory: nil){
                let strData = try String(contentsOf: FileManager.tagsFileURL, encoding: .utf8)
                print("Contents of the tagsFile:\n \(strData)")
            }else{
                let initTag: Images = Images(id: "init", tags:[], isFavorite: false)
                let encoder = JSONEncoder()
                let initJSON = try encoder.encode([initTag])
                try initJSON.write(to: FileManager.tagsFileURL, options: .atomic)
            }
            
            if FileManager.default.fileExists(atPath: FileManager.directoriesURL.path, isDirectory: nil){
                
                let strData = try String(contentsOf: FileManager.directoriesURL, encoding: .utf8)
                print("Contents of the directories:\n \(strData)")
            }else{
                let initDirectory: Directory = Directory(id: "favorites", imageIDs:[])
                let encoder = JSONEncoder()
                let initJSON = try encoder.encode([initDirectory])
                try initJSON.write(to: FileManager.directoriesURL, options: .atomic)
            }
        } catch {
            print(error)
        }
        
        return true
    }


}

