//
//  CreatePasswordViewController.swift
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
import UIKit

// Handles password creation, Firebase account registration,
// Spotify connection, and loading user data before entering the app.
class CreatePasswordViewController: UIViewController, SpotifyManagerDelegate {
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    private var spotifyLoadingAlert: UIAlertController?
    var email: String?
    let eyeButton = UIButton(type: .system)
    
    // Initializes the password field, Spotify delegate, password visibility toggle,
    // and disables the continue button until a valid password is entered.
    override func viewDidLoad() {
        super.viewDidLoad()
        spotifyManager.delegate = self
        
        passwordField.isSecureTextEntry = true
        eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeButton.tintColor = .white
        eyeButton.sizeToFit()
        eyeButton.addAction(
            UIAction(handler: togglePasswordAction),
            for: .touchUpInside
        )
        passwordField.rightView = eyeButton
        passwordField.rightViewMode = .always
        
        nextButton.isEnabled = false
        
    }
    
    // Displays a loading alert while Spotify user songs are being imported.
    func spotifyLoadingStarted() {
        let alert = UIAlertController(
            title: "Loading Your Spotify Songs...",
            message: "This may take a few seconds.",
            preferredStyle: .alert
        )
        
        spotifyLoadingAlert = alert
        present(alert, animated: true)
    }
    
    // Toggles the password field between secure and visible text entry.
    private func togglePasswordAction(_ action: UIAction) {
        passwordField.isSecureTextEntry.toggle()
        let symbol = passwordField.isSecureTextEntry ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: symbol), for: .normal)
    }
    
    // Checks password requirements and updates the continue button state.
    private func checkNextEnabled() {
        let isValid = (passwordField.text?.count ?? 0) >= 8
        nextButton.isEnabled = isValid ? true : false
        nextButton.backgroundColor = isValid ? .spotifyGreen : .spotifyGrey
        nextButton.titleLabel?.textColor = isValid ? .white : .black
        
    }
    
    // Validates the password input whenever the user edits the password field.
    @IBAction func passwordFieldEditingChanged(_ sender: UITextField) {
        checkNextEnabled()
    }
    
    // Creates a new Firebase authentication account using the provided email and password.
    @IBAction func nextButtonPressed(_ sender: Any) {
        guard let email = email, let password = passwordField.text, !password.isEmpty
        else {
            showError("Email or password is missing.")
            return
        }
        
        Auth.auth().createUser(
            withEmail: email,
            password: password) { result, error in
                if let error = error {
                    self.handleAccountCreationError(error)
                    return
                }
                
                guard let user = result?.user else {
                    self.showError(
                        "The account could not be created."
                    )
                    return
                }
                
                self.createUserDocument(user: user)
            }
    }
    
    // Creates a new Firebase authentication account using the provided email and password.
    func createUserDocument(user: User) {
        let userData: [String: Any] = ["email": user.email ?? "", "loginProvider": "email", "spotifyConnected": false, "songsImported": false]
        
        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(userData, merge: true) { error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }
                
                self.presentConnectSpotifyAlert()
            }
    }
    
    // Creates and stores a Firestore user profile after successful account creation.
    func handleAccountCreationError(_ error: Error) {
        let errorCode = AuthErrorCode(
            rawValue: (error as NSError).code
        )
        
        if errorCode == .emailAlreadyInUse {
            showError(
                    """
                    An account already exists with this email. \
                    Log in instead, or use Continue with Google \
                    if you originally registered with Google.
                    """
            )
        } else {
            showError(error.localizedDescription)
        }
    }
    
    // Presents an alert displaying an error message to the user.
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK",style: .default))
        
        self.present(alert, animated: true)
    }
    
    // Prompts the user to connect Spotify or continue without connecting.
    func presentConnectSpotifyAlert() {
        let alert = UIAlertController(
            title: "Connect Spotify?",
            message: "Connect Spotify so Heardle can use your favorite songs",
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(title: "Connect Spotify", style: .default) {
                _ in spotifyManager.connect()
            }
        )
        
        alert.addAction(
            UIAlertAction(title: "Not Now", style: .cancel) {
                _ in self.loadSongsAndGoHome()
            }
        )
        present(alert, animated: true)
    }
    
    // Navigates the user to the home screen after account setup is complete.
    func goHome() {
        performSegue(withIdentifier: "passwordToHomeSegue", sender: nil)
    }
    
    // Handles a successful Spotify login and continues loading user songs.
    func spotifyLoginSucceeded() {
        if let alert = spotifyLoadingAlert {
            alert.dismiss(animated: true) {
                self.spotifyLoadingAlert = nil
                self.loadSongsAndGoHome()
            }
        } else {
            loadSongsAndGoHome()
        }
    }
    
    // Handles Spotify connection failures and displays the associated error.
    func spotifyLoginFailed(error: Error?) {
        let message = error?.localizedDescription ?? "Could not connect Spotify."
        
        if let alert = spotifyLoadingAlert {
            alert.dismiss(animated: true) {
                self.spotifyLoadingAlert = nil
                self.showError(message)
            }
        } else {
            showError(message)
        }
    }
    
    // Loads the user's songs and navigates to the home screen once loading finishes.
    private func loadSongsAndGoHome() {
        Task {
            let loadedSongs = await songService.fetchSongsForCurrentUser()
            
            guard !loadedSongs.isEmpty else {
                self.showError("Songs could not be loaded.")
                return
            }
            
            songs = loadedSongs
            self.goHome()
        }
    }
    
}
