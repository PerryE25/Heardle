//
//  SpotifyManager.swift
//  Heardle
//
//  Created by Memon, Haroon on 7/16/26.
//

import Foundation
import SpotifyLogin
import FirebaseFunctions
import FirebaseAuth
protocol SpotifyManagerDelegate{
    func spotifyLoginSucceeded()
    func spotifyLoginFailed(error: Error?)
}

let spotifyManager = SpotifyManager()

class SpotifyManager: NSObject, SessionManagerDelegate{
    func sessionManager(manager: SpotifyLogin.SessionManager, didInitiate session: SpotifyLogin.Session) {
        //auth succeded
        signIntoFirebase(spotifyAccessToken: session.accessToken)
    }
    
    func sessionManager(manager: SpotifyLogin.SessionManager, didFailWith error: any Error) {
        print("spotify auth failed: \(error.localizedDescription)")
        delegate?.spotifyLoginFailed(error: error)
    }
    
    var delegate: SpotifyManagerDelegate?
    
    var sessionManager: SessionManager!
    
    override init(){
        super.init()
        
        let configuration = Configuration(clientID: "488a5b1453634b68bc6a0905dcc0f0c9", redirectURL: URL(string: "utcs.heardle://spotify-login-callback")!)
        
        sessionManager = SessionManager(configuration: configuration, delegate: self)
    }
    
    func login(){
        let scopes : [Scope] = [.userReadPrivate, .userReadEmail, .userLibraryRead, .playlistReadPrivate]
        
        sessionManager.initiateSession(with: scopes, authorizationFlow: .default)
        
    }
    func handleCallback(url: URL){
        sessionManager.openURL(url)
    }
    
    func signIntoFirebase(spotifyAccessToken: String){
        let function = Functions.functions().httpsCallable("spotifySignIn")
        function.call(["accessToken": spotifyAccessToken]) { (result, error) in
            if let error = error{
                print("error: \(error.localizedDescription)")
                return
            }
            let data = result?.data as? [String: Any]
            
            guard let customToken = data?["customToken"] as? String else {
                    print("No custom token returned")
                    self.delegate?.spotifyLoginFailed(error: nil)
                    return
                }
            
            Auth.auth().signIn(withCustomToken: customToken) { (result, error) in
                if let error = error{
                    print("error: \(error.localizedDescription)")
                    return
                }
                self.delegate?.spotifyLoginSucceeded()
            }
        }
        
    }
    
    
    
    

}
