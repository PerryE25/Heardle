//
//  SpotifyManager.swift
//  Heardle
//
//  Created by Memon, Haroon on 7/16/26.
//

import Foundation
import SpotifyiOS
import FirebaseFunctions
import FirebaseAuth
protocol SpotifyManagerDelegate{
    func spotifyLoginSucceeded()
    func spotifyLoginFailed()
}

let spotifyManager = SpotifyManager()

class SpotifyManager: NSObject, SPTAppRemoteDelegate{
    
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: (any Error)?) {
        delegate?.spotifyLoginFailed()
        print("Connection failed")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: (any Error)?) {
        delegate?.spotifyLoginFailed()
        print("Spotify disconnected")
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        delegate?.spotifyLoginSucceeded()
        print("Connected to Spotify")
    }
    
    
    let appRemote: SPTAppRemote
    
    var delegate: SpotifyManagerDelegate?
    
    override init(){
        let configuration = SPTConfiguration(clientID: "488a5b1453634b68bc6a0905dcc0f0c9", redirectURL: URL(string: "utcs.heardle://spotify-login-callback")!)
         appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        super.init()
        appRemote.delegate = self
    }
    
    func login(){
        appRemote.authorizeAndPlayURI("", asRadio: false, additionalScopes: ["user-read-private"])
    }
    
    func handleCallback(url: URL){
        guard let parameters = appRemote.authorizationParameters(from: url) else {
            print("invalid spotify callback")
            delegate?.spotifyLoginFailed()
            return
        }
        
        if let errorMessage = parameters[SPTAppRemoteErrorDescriptionKey]{
            print("Spotify error \(errorMessage)")
            delegate?.spotifyLoginFailed()
            return
        }
        
        guard let accessToken = parameters[SPTAppRemoteAccessTokenKey] else{
            print("No access token")
            delegate?.spotifyLoginFailed()
            return
        }
        appRemote.connectionParameters.accessToken = accessToken
            
        appRemote.connect()
        
        signIntoFirebase(spotifyAccessToken: accessToken)
        
    }
    func signIntoFirebase(spotifyAccessToken: String){
        let function = Functions.functions().httpsCallable("spotifySignIn")
        function.call(["accessToken": spotifyAccessToken]) { (result, error) in
            if let error = error {
                print(error)
                self.delegate?.spotifyLoginFailed()
                return
            }
            
            let data = result?.data as? [String: Any]
            guard let customToken = data?["customToken"] as? String else{
                print("No custom token received")
                self.delegate?.spotifyLoginFailed()
                return
            }
            
            Auth.auth().signIn(withCustomToken: customToken){
                authResult, error in
                if let error = error{
                    print("Firebase login error \(error.localizedDescription)")
                    self.delegate?.spotifyLoginFailed()
                    return
                }
                
                self.delegate?.spotifyLoginSucceeded()
            }
            
            

        }
        
        
    }

}
