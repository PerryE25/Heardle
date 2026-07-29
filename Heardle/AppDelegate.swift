//
//  AppDelegate.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit
import FirebaseCore
import SpotifyiOS

// Application delegate handling launch and scene session lifecycle.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Configure Firebase, UI defaults, and preload user songs on app launch.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up default songs and firebase
        FirebaseApp.configure()
        UIView.setAnimationsEnabled(
            !UserDefaults.standard.bool(forKey: skipAnimationsEnabledKey)
        )
        
        Task {
            let loadedSongs = await songService.fetchSongsForCurrentUser()
            
            if songs.isEmpty {
                songs = loadedSongs
            }
            
            print("Fetched \(songs.count) songs")
            
            guard !songs.isEmpty else {
                print("No songs found")
                return
            }
        }
        return true
    }
    
    // Provide a configuration when creating a new scene session.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // Handle cleanup for discarded scene sessions.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}
