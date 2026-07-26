//
//  LoginViewController.swift
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
import GoogleSignIn
import FirebaseCore

// Handles user login via Spotify, Google, and email/password.
class LoginViewController: UIViewController, SpotifyManagerDelegate {

    private var spotifyLoadingAlert: UIAlertController?

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

    // Dismisses the loading alert (if shown) and presents an error.
    func spotifyLoginFailed(error: Error?) {
        let message = error?.localizedDescription ?? "Spotify login failed."

        if let alert = spotifyLoadingAlert {
            alert.dismiss(animated: true) {
                self.spotifyLoadingAlert = nil
                self.showError(message)
            }
        } else {
            showError(message)
        }
    }
    

    @IBOutlet weak var spotifyButton: UIButton!
    
    @IBOutlet weak var googleButton: UIButton!
    
    @IBOutlet weak var appleButton: UIButton!
    
    // Starts the Spotify login flow.
    @IBAction func spotifyButtonPressed(_ sender: Any) {
        spotifyManager.login()
    }

    // Prompts the user to log in with email and password.
    @IBAction func emailLoginButtonPressed(_ sender: Any) {
        presentEmailLoginAlert()
    }
    
    // Starts the Google sign-in flow and signs into Firebase.
    @IBAction func googleButtonPressed(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: self){ result, error in
            guard error == nil else{
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                guard error == nil else {
                    return
                }
                guard let user = authResult?.user else{
                    return
                }
                self.checkSpotifyConnection(for: user, loginProvider: "google")
            }
            
        }
    }
    
    
    // Configures UI elements and sets up third-party login button icons.
    override func viewDidLoad() {
        super.viewDidLoad()
        spotifyManager.delegate = self
        if let icon = UIImage(named: "spotify-xxl"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            spotifyButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            spotifyButton.configuration?.imagePadding = 10
            spotifyButton.layer.borderColor = UIColor.darkGray.cgColor
            spotifyButton.layer.borderWidth = 1.0
            spotifyButton.layer.cornerRadius = 6
        }
        
        if let icon = UIImage(named: "Google_\"G\"_logo.svg"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            googleButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            googleButton.configuration?.imagePadding = 10
            googleButton.layer.borderColor = UIColor.darkGray.cgColor
            googleButton.layer.borderWidth = 1.0
            googleButton.layer.cornerRadius = 6
        }
        if let icon = UIImage(named: "Apple_logo_white.svg"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            appleButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            appleButton.configuration?.imagePadding = 10
            appleButton.layer.borderColor = UIColor.darkGray.cgColor
            appleButton.layer.borderWidth = 1.0
            appleButton.layer.cornerRadius = 6
        }
        // Do any additional setup after loading the view.
    }
    
    // Dismisses loading and continues to load songs when Spotify login succeeds.
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

    // Presents an alert to capture email and password for login.
    private func presentEmailLoginAlert() {
        let alert = UIAlertController(
            title: "Log in",
            message: "Enter your email and password.",
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.placeholder = "Email"
            field.keyboardType = .emailAddress
            field.autocapitalizationType = .none
        }

        alert.addTextField { field in
            field.placeholder = "Password"
            field.isSecureTextEntry = true
        }

        let emailField = alert.textFields![0]
        let passwordField = alert.textFields![1]

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log in", style: .default) { _ in
            let email = emailField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let password = passwordField.text ?? ""

            guard !email.isEmpty, !password.isEmpty else {
                self.showError("Enter your email and password.")
                return
            }

            self.signInWithEmail(email, password: password)
        })

        present(alert, animated: true)
    }

    // Signs in with email/password and checks Spotify connection.
    private func signInWithEmail(_ email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error {
                self.showError(error.localizedDescription)
                return
            }

            guard let user = result?.user else {
                self.showError("The account could not be loaded.")
                return
            }

            self.checkSpotifyConnection(for: user, loginProvider: "email")
        }
    }

    // Ensures a Firestore user document exists and prompts to connect Spotify if needed.
    private func checkSpotifyConnection(for user: User, loginProvider: String) {
        let document = Firestore.firestore().collection("users").document(user.uid)
            document.getDocument { snapshot, error in
                if let error {
                    self.showError(error.localizedDescription)
                    return
                }
                
                if snapshot?.exists != true {
                    document.setData([
                        "email": user.email ?? "",
                        "displayName": user.displayName ?? "",
                        "loginProvider": loginProvider,
                        "spotifyConnected": false,
                        "songsImported": false
                    ]) { error in
                        if let error = error {
                            self.showError(error.localizedDescription)
                            return
                        }

                        self.presentConnectSpotifyAlert()
                    }
                    return
                }

                let data = snapshot?.data()
                let spotifyConnected =
                    data?["spotifyConnected"] as? Bool ?? false
                let songsImported =
                    data?["songsImported"] as? Bool ?? false

                if spotifyConnected && songsImported {
                    self.loadSongsAndGoHome()
                } else {
                    self.presentConnectSpotifyAlert()
                }
            }
    }

    // Prompts the user to connect Spotify or skip.
    private func presentConnectSpotifyAlert() {
        let alert = UIAlertController(
            title: "Connect Spotify?",
            message: "Connect Spotify so Heardle can use your favorite songs.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Connect Spotify", style: .default) {
            _ in spotifyManager.connect()
        })

        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel) {
            _ in self.loadSongsAndGoHome()
        })

        present(alert, animated: true)
    }

    // Shows a generic login error alert with the provided message.
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Login Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

    // Performs the segue to the home screen.
    private func goHome() {
        performSegue(withIdentifier: "loginToHomeSegue", sender: self)
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

