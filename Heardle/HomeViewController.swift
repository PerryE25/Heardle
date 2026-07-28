//
//  HomeViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import PhotosUI
import SpotifyLogin
import UIKit

var gameUser = GameUser(displayName: "User25", points: 0, displayImage: nil)

// A class for the home screen of the app
class HomeViewController: UIViewController {
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var displayPtsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayImageView.frame.size.width = 100
        displayImageView.frame.size.height = 100
        displayImageView.layer.cornerRadius = displayImageView.frame.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDisplayName()
        loadProfilePicture()
        loadPoints()
    }
    
    // Loads the display name from Firestore (or Spotify/user defaults as fallback).
    func loadDisplayName() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let data = snapshot?.data()
                let savedName = data?["displayName"] as? String ?? ""
                let spotifyName = data?["spotifyDisplayName"] as? String ?? ""
                let email = user.email ?? ""
                let emailName = email.components(separatedBy: "@").first ?? ""

                if !savedName.isEmpty {
                    self.displayNameLabel.text = savedName
                    gameUser.displayName = savedName
                } else if !spotifyName.isEmpty {
                    self.displayNameLabel.text = spotifyName
                    gameUser.displayName = spotifyName
                } else {
                    self.displayNameLabel.text = emailName
                    gameUser.displayName = emailName
                }
            }
    }
    
    // Loads the profile picture from Firestore/Spotify and displays it.
    func loadProfilePicture() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let data = snapshot?.data()
                let pictureURL =
                    data?["profilePictureURL"] as? String
                    ?? data?["spotifyProfilePictureURL"] as? String

                guard let pictureURL = pictureURL,
                    let url = URL(string: pictureURL)
                else {
                    // no img, use default instead
                    self.displayImageView.image = UIImage(named: "green_headphones")
                    return
                }

                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(
                            from: url
                        )
                        guard let image = UIImage(data: data) else { return }
                        DispatchQueue.main.async {
                            self.displayImageView.image = image
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
    }
    
    func loadPoints() {
        guard let user = Auth.auth().currentUser else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                let data = snapshot?.data()
                let savedPts = data?["points"] as? Int ?? 0
                self.displayPtsButton.setTitle(String(savedPts), for: .normal)
            }
    }
    
    // Unwind segue action for returning to home from game results
    @IBAction func unwindToHome(_ unwindSegue: UIStoryboardSegue) {
        // This method allows other view controllers to unwind back to HomeViewController
        print("[HOME] Unwound back to home from \(type(of: unwindSegue.source))")
        // Any cleanup or refresh logic can go here
    }

}
