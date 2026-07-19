//
//  SpotifyManager.swift
//  Heardle
//
//  Created by Memon, Haroon on 7/16/26.
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

class SpotifyManager: NSObject, SessionManagerDelegate {
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

    func sessionManager(
        manager: SpotifyLogin.SessionManager,
        didFailWith error: any Error
    ) {
        print("spotify auth failed: \(error.localizedDescription)")
        delegate?.spotifyLoginFailed(error: error)
    }

    var delegate: SpotifyManagerDelegate?

    var sessionManager: SessionManager!

    var connectingExistingAccount = false

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

    func login() {
        connectingExistingAccount = false
        startSpotifyAuthorization()
    }

    func connect() {
        connectingExistingAccount = true
        startSpotifyAuthorization()
    }

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

    func handleCallback(url: URL) {
        sessionManager.openURL(url)
    }

    func finishSpotifySetup(
        user: User,
        spotifyAccessToken: String
    ) {
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

    func signIntoFirebase(spotifyAccessToken: String) {
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

                Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .setData(
                        [
                        "loginProvider": "spotify",
                        "spotifyConnected": true,
                        "spotifyAccountID": spotifyID,
                        "spotifyDisplayName": displayName,
                        ],
                        merge: true
                    ) { error in
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
    func connectSpotify(spotifyAccessToken: String) {
        guard let user = Auth.auth().currentUser else {
            print("No Firebase user signed in")
            delegate?.spotifyLoginFailed(error: nil)
            return
        }

        let function = Functions.functions().httpsCallable("spotifySignIn")

        function.call(["accessToken": spotifyAccessToken]) { result, error in
            if let error = error {
                print(error.localizedDescription)
                self.delegate?.spotifyLoginFailed(error: error)
                return
            }

            let data = result?.data as? [String: Any]

            guard let spotifyID = data?["spotifyAccountID"] as? String else {
                print("Spotify ID missing")
                self.delegate?.spotifyLoginFailed(error: nil)
                return
            }

            let spotifyName = data?["spotifyDisplayName"] as? String ?? ""

            Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .setData(
                    [
                        "spotifyConnected": true,
                        "spotifyAccountID": spotifyID,
                        "spotifyDisplayName": spotifyName,
                    ],
                    merge: true
                ) { error in
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
