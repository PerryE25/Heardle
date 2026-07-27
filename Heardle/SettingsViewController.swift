//
//  SettingsViewController.swift
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

let hapticsEnabledKey = "hapticsEnabled"
let skipAnimationsEnabledKey = "skipAnimationsEnabled"

// Manages profile settings, Spotify connection, and gameplay preferences.
class SettingsViewController: UIViewController, PHPickerViewControllerDelegate {
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var spotifyTitleLabel: UILabel!
    @IBOutlet weak var spotifySubtitleLabel: UILabel!
    @IBOutlet weak var hapticsSwitch: UISwitch!
    @IBOutlet weak var skipAnimationsSwitch: UISwitch!

    var spotifyIsConnected = false
    var spotifyName = ""

    // Dismisses the settings screen.
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }

    // Loads profile data, Spotify status, and gameplay settings.
    override func viewDidLoad() {
        super.viewDidLoad()

        loadDisplayName()
        loadProfilePicture()
        loadSpotifyConnection()
        loadGameplaySettings()
    }

    // Loads and applies stored preferences for haptics and animations.
    func loadGameplaySettings() {
        let savedHaptics =
            UserDefaults.standard.object(
                forKey: hapticsEnabledKey
            ) as? Bool

        hapticsSwitch.isOn = savedHaptics ?? true
        skipAnimationsSwitch.isOn = UserDefaults.standard.bool(
            forKey: skipAnimationsEnabledKey
        )
    }

    // Saves the haptics preference and provides haptic feedback when enabled.
    @IBAction func hapticsSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: hapticsEnabledKey)

        if sender.isOn {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // Saves the skip animations preference and toggles UIView animations.
    @IBAction func skipAnimationsSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(
            sender.isOn,
            forKey: skipAnimationsEnabledKey
        )
        UIView.setAnimationsEnabled(!sender.isOn)
    }

    // Loads the display name from Firestore (or Spotify/user defaults as fallback).
    func loadDisplayName() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }

                let data = snapshot?.data()
                let savedName = data?["displayName"] as? String ?? ""
                let spotifyName = data?["spotifyDisplayName"] as? String ?? ""
                let email = user.email ?? ""
                let emailName = email.components(separatedBy: "@").first ?? ""

                if !savedName.isEmpty {
                    self.nameTextField.text = savedName
                } else if !spotifyName.isEmpty {
                    self.nameTextField.text = spotifyName
                } else {
                    self.nameTextField.text = emailName
                }
            }
    }

    // Validates and saves the display name to Firestore.
    @IBAction func displayNameEditingDidEnd(_ sender: UITextField) {
        guard let user = Auth.auth().currentUser else { return }

        let displayName =
            sender.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !displayName.isEmpty else {
            showError("Display name cannot be empty.")
            loadDisplayName()
            return
        }

        sender.text = displayName

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(
                ["displayName": displayName],
                merge: true
            ) { error in
                if let error = error {
                    self.showError(error.localizedDescription)
                }
            }
    }
    // Loads Spotify connection status and display name from Firestore.
    func loadSpotifyConnection() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }

                let data = snapshot?.data()
                self.spotifyIsConnected =
                    data?["spotifyConnected"] as? Bool ?? false
                self.spotifyName =
                    data?["spotifyDisplayName"] as? String ?? "Spotify User"
                self.updateSpotifyConnectionLabel()
            }
    }

    // Updates the Spotify connection labels based on current state.
    func updateSpotifyConnectionLabel() {
        spotifyTitleLabel.text =
            spotifyIsConnected
            ? "Spotify Connected"
            : "Spotify Not Connected"
        spotifySubtitleLabel.text =
            spotifyIsConnected
            ? "Connected as \(spotifyName)"
            : "No Spotify account connected"
        spotifySubtitleLabel.textColor =
            spotifyIsConnected
            ? UIColor.spotifyGreen
            : UIColor.lightGray
    }

    // Shows an alert to disconnect Spotify or informs the current status.
    @IBAction func spotifyConnectionPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: spotifyIsConnected
                ? "Spotify Connected"
                : "Spotify Not Connected",
            message: spotifyIsConnected
                ? "Connected as \(spotifyName)."
                : "There is no Spotify account connected.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if spotifyIsConnected {
            alert.addAction(
                UIAlertAction(
                    title: "Disconnect Spotify",
                    style: .destructive
                ) { _ in
                    self.disconnectSpotify()
                }
            )
        }

        present(alert, animated: true)
    }

    // Disconnects Spotify and removes imported songs and metadata from Firestore.
    func disconnectSpotify() {
        guard let user = Auth.auth().currentUser else { return }

        Task {
            do {
                let userDocument = Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                let importedSongs =
                    try await userDocument
                    .collection("songs")
                    .getDocuments()
                let batch = Firestore.firestore().batch()

                for song in importedSongs.documents {
                    batch.deleteDocument(song.reference)
                }

                batch.updateData(
                    [
                        "spotifyConnected": false,
                        "songsImported": false,
                        "spotifyAccountID": FieldValue.delete(),
                        "spotifyDisplayName": FieldValue.delete(),
                        "spotifyProfilePictureURL": FieldValue.delete(),
                        "songsImportedAt": FieldValue.delete(),
                    ],
                    forDocument: userDocument
                )

                try await batch.commit()

                spotifyManager.sessionManager.session = nil
                spotifyIsConnected = false
                spotifyName = ""
                updateSpotifyConnectionLabel()
                songs = await songService.fetchSongsForCurrentUser()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    // Signs the user out and returns to the login screen.
    @IBAction func signOutPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Sign Out?",
            message: "You can sign back in at any time.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(
            UIAlertAction(
                title: "Sign Out",
                style: .destructive
            ) { _ in
                do {
                    try Auth.auth().signOut()
                    GIDSignIn.sharedInstance.signOut()
                    spotifyManager.sessionManager.session = nil
                    self.showLoginScreen()
                } catch {
                    self.showError(error.localizedDescription)
                }
            }
        )

        present(alert, animated: true)
    }

    // Prompts to permanently delete the account and imported data.
    @IBAction func deleteAccountPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Account?",
            message:
                "This permanently deletes your profile and imported songs.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(
            UIAlertAction(
                title: "Delete Account",
                style: .destructive
            ) { _ in
                self.deleteAccount()
            }
        )

        present(alert, animated: true)
    }

    // Deletes the Firebase user, Firestore data, and profile picture.
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }

        Task {
            do {
                // Delete the account first: if this fails (e.g. the user
                // needs to sign in again), nothing else has been touched yet.
                try await user.delete()

                let userDocument = Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                let importedSongs =
                    try await userDocument
                    .collection("songs")
                    .getDocuments()
                let batch = Firestore.firestore().batch()

                for song in importedSongs.documents {
                    batch.deleteDocument(song.reference)
                }

                batch.deleteDocument(userDocument)
                try await batch.commit()

                try? await Storage.storage().reference()
                    .child("profilePictures/\(user.uid).jpg")
                    .delete()

                GIDSignIn.sharedInstance.signOut()
                spotifyManager.sessionManager.session = nil
                songs = []
                showLoginScreen()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    // Navigates back to the login screen.
    func showLoginScreen() {
        performSegue(withIdentifier: "settingsToLoginSegue", sender: self)
    }

    // Presents the photo picker to update the profile picture.
    @IBAction func editButtonPressed(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    // Handles a selected image and starts saving it to storage and Firestore.
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        provider.loadObject(ofClass: UIImage.self) { object, error in
            DispatchQueue.main.async {
                guard let image = object as? UIImage else {
                    self.showError(
                        error?.localizedDescription ?? "Could not load that photo."
                    )
                    return
                }

                self.profilePictureImageView.image = image
                self.saveProfilePicture(image)
            }
        }
    }

    // Uploads the profile picture to Firebase Storage and saves its URL in Firestore.
    func saveProfilePicture(_ image: UIImage) {
        guard let user = Auth.auth().currentUser,
            let imageData = image.jpegData(compressionQuality: 0.7)
        else {
            showError("Could not save your profile picture.")
            return
        }

        let imageReference = Storage.storage().reference()
            .child("profilePictures/\(user.uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageReference.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }

            imageReference.downloadURL { url, error in
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }

                guard let url = url else { return }

                Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .setData(
                        ["profilePictureURL": url.absoluteString],
                        merge: true
                    ) { error in
                        if let error = error {
                            self.showError(error.localizedDescription)
                        }
                    }
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
                    self.showError(error.localizedDescription)
                    return
                }

                let data = snapshot?.data()
                let pictureURL =
                    data?["profilePictureURL"] as? String
                    ?? data?["spotifyProfilePictureURL"] as? String

                guard let pictureURL = pictureURL,
                    let url = URL(string: pictureURL)
                else { return }

                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(
                            from: url
                        )
                        guard let image = UIImage(data: data) else { return }
                        DispatchQueue.main.async {
                            self.profilePictureImageView.image = image
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.showError(error.localizedDescription)
                        }
                    }
                }
            }
    }

    // Presents a generic settings error alert.
    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Settings Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // Rounds the profile image and edit button after layout updates.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profilePictureImageView.layer.cornerRadius =
            profilePictureImageView.bounds.width / 2
        profilePictureImageView.clipsToBounds = true

        editButton.layer.cornerRadius = editButton.bounds.height / 2
        editButton.clipsToBounds = true
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
