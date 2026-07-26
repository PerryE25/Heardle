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

// Creates a password for new accounts and optionally connects Spotify.
class CreatePasswordViewController: UIViewController, SpotifyManagerDelegate {

    // Presents a loading alert while Spotify songs are being prepared.
    func spotifyLoadingStarted() {
        let alert = UIAlertController(
            title: "Loading Your Spotify Songs...",
            message: "This may take a few seconds.",
            preferredStyle: .alert
        )

        spotifyLoadingAlert = alert
        present(alert, animated: true)
    }

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    var email: String?
    let eyeButton = UIButton(type: .system)

    // Configures the password field, eye toggle, and initial button state.
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

    // Toggles secure entry and updates the eye icon.
    private func togglePasswordAction(_ action: UIAction) {
        passwordField.isSecureTextEntry.toggle()
        let symbol = passwordField.isSecureTextEntry ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: symbol), for: .normal)
    }

    // Enables or disables the Next button based on password length.
    private func checkNextEnabled() {
        let isValid = (passwordField.text?.count ?? 0) >= 8
        nextButton.isEnabled = isValid ? true : false
        nextButton.backgroundColor = isValid ? .spotifyGreen : .spotifyGrey
        nextButton.titleLabel?.textColor = isValid ? .white : .black

    }

    // Revalidates the Next button as the user types.
    @IBAction func passwordFieldEditingChanged(_ sender: UITextField) {
        checkNextEnabled()
    }

    // Creates the Firebase account and user document, then prompts Spotify connect.
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
    
    // Creates/merges the Firestore user document with default flags.
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

    // Presents a friendly message for common account creation errors.
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

    // Shows a generic error alert.
    func showError(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK",style: .default))
            
            self.present(alert, animated: true)
    }

    // Prompts the user to connect Spotify or skip.
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

    // Performs the segue to the home screen.
    func goHome() {
        performSegue(withIdentifier: "passwordToHomeSegue", sender: nil)
    }
    
    // Dismisses loading and continues to load songs when Spotify login succeeds.
    func spotifyLoginSucceeded(){
        if let alert = spotifyLoadingAlert {
            alert.dismiss(animated: true) {
                self.spotifyLoadingAlert = nil
                self.loadSongsAndGoHome()
            }
        } else {
            loadSongsAndGoHome()
        }
    }
    
    // Dismisses loading and shows an error if Spotify login fails.
    func spotifyLoginFailed(error: Error?){
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

    // Loads the user's songs and navigates to the home screen.
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

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
