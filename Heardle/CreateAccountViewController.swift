//
//  CreateAccountViewController.swift
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

class CreateAccountViewController: UIViewController, SpotifyManagerDelegate {

    private var spotifyLoadingAlert: UIAlertController?

    func spotifyLoadingStarted() {
        let alert = UIAlertController(
            title: "Loading Your Spotify Songs...",
            message: "This may take a few seconds.",
            preferredStyle: .alert
        )

        spotifyLoadingAlert = alert
        present(alert, animated: true)
    }

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
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        let email = emailField.text ?? ""
        if !(email == "") {
            performSegue(withIdentifier: "accountToPasswordSegue", sender: nil)
        }
    }
    
    @IBAction func spotifyButtonPressed(_ sender: Any) {
        spotifyManager.login()
    }

    @IBAction func emailLoginButtonPressed(_ sender: Any) {
        presentEmailLoginAlert()
    }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spotifyManager.delegate = self
        emailField.layer.borderColor = UIColor.darkGray.cgColor
        emailField.layer.borderWidth = 1.0
        emailField.layer.cornerRadius = 6
        
        if let icon = UIImage(named: "spotify-xxl"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            spotifyButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            spotifyButton.configuration?.imagePadding = 10
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

    func presentEmailLoginAlert() {
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

    func signInWithEmail(_ email: String, password: String) {
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

    func checkSpotifyConnection(for user: User, loginProvider: String) {
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

    func presentConnectSpotifyAlert() {
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

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Login Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

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

    private func goHome() {
        performSegue(withIdentifier: "accountToHomeSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "accountToPasswordSegue"{
            let passwordVC = segue.destination as! CreatePasswordViewController
            
            passwordVC.email = emailField.text!
        }
    }

}
