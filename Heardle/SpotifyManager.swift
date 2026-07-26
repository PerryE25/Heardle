//
//  SpotifyManager.swift
//  Heardle
//
//  Created by Memon, Haroon on 7/16/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Foundation
import SpotifyLogin

protocol SpotifyManagerDelegate {
    func spotifyLoadingStarted()
    func spotifyLoginSucceeded()
    func spotifyLoginFailed(error: Error?)
}

let spotifyManager = SpotifyManager()

// Manages Spotify authentication and Firebase sign-in/connection flows.
class SpotifyManager: NSObject, SessionManagerDelegate {
    // Called when Spotify auth succeeds; continues sign-in or connect flow.
    func sessionManager(
        manager: SpotifyLogin.SessionManager,
        didInitiate session: SpotifyLogin.Session
    ) {
        delegate?.spotifyLoadingStarted()

        if connectingExistingAccount {
            connectSpotify(spotifyAccessToken: session.accessToken)
        } else {
            signIntoFirebase(spotifyAccessToken: session.accessToken)
        }
    }

    // Called when Spotify auth fails; notifies the delegate of the error.
    func sessionManager(
        manager: SpotifyLogin.SessionManager,
        didFailWith error: any Error
    ) {
        print("calls session manager2")
        print("spotify auth failed: \(error.localizedDescription)")
        delegate?.spotifyLoginFailed(error: error)
    }

    var delegate: SpotifyManagerDelegate?

    var sessionManager: SessionManager!

    var connectingExistingAccount = false

    // Initializes the Spotify session manager with client credentials.
    override init() {
        super.init()

        let configuration = Configuration(
            clientID: "488a5b1453634b68bc6a0905dcc0f0c9",
            redirectURL: URL(string: "utcs.heardle://spotify-login-callback")!
        )

        sessionManager = SessionManager(
            configuration: configuration,
            delegate: self
        )
    }

    // Starts the Spotify login flow for new sign-ins.
    func login() {
        print("login is called")
        connectingExistingAccount = false
        startSpotifyAuthorization()
    }

    // Starts the Spotify connect flow for existing users.
    func connect() {
        connectingExistingAccount = true
        startSpotifyAuthorization()
    }

    // Initiates Spotify authorization with required scopes.
    func startSpotifyAuthorization() {
        let scopes: [Scope] = [
            .userReadPrivate, .userReadEmail, .userLibraryRead,
            .playlistReadPrivate, .userTopRead,
        ]
        sessionManager.initiateSession(
            with: scopes,
            authorizationFlow: .default
        )

    }

    // Forwards the OAuth callback URL to the session manager.
    func handleCallback(url: URL) {
        sessionManager.openURL(url)
    }

    // Imports songs if needed and notifies the delegate upon completion.
    func finishSpotifySetup(
        user: User,
        spotifyAccessToken: String
    ) {
        print("finishSpotifySetup is called")
        Task {
            let success = await songImporter.importSongsIfNeeded(
                spotifyAccessToken: spotifyAccessToken,
                user: user
            )

            if success {
                self.delegate?.spotifyLoginSucceeded()
            } else {
                self.delegate?.spotifyLoginFailed(error: nil)
            }
        }
    }

    // Retrieves the user's Spotify profile picture URL.
    func fetchSpotifyProfilePicture(
        spotifyAccessToken: String,
        completion: @escaping (String?) -> Void
    ) {
        print("fetchSpotifyProfilePicture is called")
        guard let url = URL(string: "https://api.spotify.com/v1/me") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Bearer \(spotifyAccessToken)",
            forHTTPHeaderField: "Authorization"
        )

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any]
                let images = json?["images"] as? [[String: Any]]
                completion(images?.first?["url"] as? String)
            } catch {
                completion(nil)
            }
        }
    }

    // Exchanges the Spotify token for a Firebase custom token and signs in.
    func signIntoFirebase(spotifyAccessToken: String) {
        print("signIntoFirebase is called")
        let function = Functions.functions()
            .httpsCallable("spotifySignIn")

        function.call([
            "accessToken": spotifyAccessToken
        ]) { result, error in

            if let error = error {
                print(error.localizedDescription)
                self.delegate?.spotifyLoginFailed(error: error)
                return
            }

            let data = result?.data as? [String: Any]

            guard
                let customToken =
                    data?["customToken"] as? String,
                let spotifyID =
                    data?["spotifyAccountID"] as? String
            else {
                print("Spotify information missing")
                self.delegate?.spotifyLoginFailed(error: nil)
                return
            }

            let displayName =
                data?["spotifyDisplayName"] as? String
                ?? "Spotify User"

            Auth.auth().signIn(
                withCustomToken: customToken
            ) { authResult, error in

                if let error = error {
                    print(error.localizedDescription)
                    self.delegate?.spotifyLoginFailed(error: error)
                    return
                }

                guard let user = authResult?.user else {
                    print("Firebase user missing")
                    self.delegate?.spotifyLoginFailed(error: nil)
                    return
                }

                self.fetchSpotifyProfilePicture(
                    spotifyAccessToken: spotifyAccessToken
                ) { profilePictureURL in
                    var userData: [String: Any] = [
                        "loginProvider": "spotify",
                        "spotifyConnected": true,
                        "spotifyAccountID": spotifyID,
                        "spotifyDisplayName": displayName,
                    ]

                    if let profilePictureURL = profilePictureURL {
                        userData["spotifyProfilePictureURL"] = profilePictureURL
                    }

                    Firestore.firestore()
                        .collection("users")
                        .document(user.uid)
                        .setData(userData, merge: true) { error in
                            if let error = error {
                                print(error.localizedDescription)
                                self.delegate?.spotifyLoginFailed(error: error)
                                return
                            }

                            self.finishSpotifySetup(
                                user: user,
                                spotifyAccessToken: spotifyAccessToken
                            )
                        }
                }
            }
        }
    }
    // Connects Spotify to an existing Firebase account and finalizes setup.
    func connectSpotify(spotifyAccessToken: String) {
        print("connecting spotify")
        guard let user = Auth.auth().currentUser else {
            print("No Firebase user signed in")
            delegate?.spotifyLoginFailed(error: nil)
            return
        }
        print("access token: \(spotifyAccessToken)")
        let function = Functions.functions().httpsCallable("spotifySignIn")

        function.call(["accessToken": spotifyAccessToken]) { result, error in
            if let error = error {
                print("ERROR:", error)

                if let error = error as NSError? {
                    print("Domain:", error.domain)
                    print("Code:", error.code)
                    print("UserInfo:", error.userInfo)
                }
                
                print(error.localizedDescription)
                self.delegate?.spotifyLoginFailed(error: error)
                return
            }

            print("Cloud Function result:")
            print(result?.data ?? "nil")

            let data = result?.data as? [String: Any]
            print("Parsed data:", data ?? [:])

            guard let spotifyID = data?["spotifyAccountID"] as? String else {
                print("Spotify ID missing")
                self.delegate?.spotifyLoginFailed(error: nil)
                return
            }

            let spotifyName = data?["spotifyDisplayName"] as? String ?? ""

            self.fetchSpotifyProfilePicture(
                spotifyAccessToken: spotifyAccessToken
            ) { profilePictureURL in
                var userData: [String: Any] = [
                    "spotifyConnected": true,
                    "spotifyAccountID": spotifyID,
                    "spotifyDisplayName": spotifyName,
                ]

                if let profilePictureURL = profilePictureURL {
                    userData["spotifyProfilePictureURL"] = profilePictureURL
                }

                Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .setData(userData, merge: true) { error in
                        if let error = error {
                            print(error.localizedDescription)
                            self.delegate?.spotifyLoginFailed(error: error)
                            return
                        }

                        self.finishSpotifySetup(
                            user: user,
                            spotifyAccessToken: spotifyAccessToken
                        )
                    }
            }
        }
    }

}
