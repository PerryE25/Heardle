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

class LoginViewController: UIViewController, SpotifyManagerDelegate {
    var isNavigatingHome = false

    func spotifyLoginFailed(error: Error?) {
        showError(error?.localizedDescription ?? "Spotify login failed.")
    }
    

    @IBOutlet weak var spotifyButton: UIButton!
    
    @IBOutlet weak var googleButton: UIButton!
    
    @IBOutlet weak var appleButton: UIButton!
    
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
    
    func spotifyLoginSucceeded() {
        goHome()
    }

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

    private func checkSpotifyConnection(for user: User, loginProvider: String) {
        let document = Firestore.firestore().collection("users").document(user.uid)
            document.getDocument { snapshot, error in
                if let error {
                    self.showError(error.localizedDescription)
                    return
                }
                
                if snapshot?.exists == false {
                    document.setData([
                        "email": user.email ?? "",
                        "displayName": user.displayName ?? "",
                        "loginProvider": loginProvider,
                        "spotifyConnected": false,
                        "songsImported": false
                    ])
                    self.presentConnectSpotifyAlert()
                    return
                }

                let spotifyConnected =
                    snapshot?.data()?["spotifyConnected"] as? Bool ?? false

                if spotifyConnected {
                    self.goHome()
                } else {
                    self.presentConnectSpotifyAlert()
                }
            }
    }

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
            _ in self.goHome()
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

    private func goHome() {
        guard !isNavigatingHome else { return }
        isNavigatingHome = true
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
