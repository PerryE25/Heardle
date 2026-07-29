//
//  SpotifyManagerDelegate.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/28/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

// A delegate for mediating spotify connectivity
protocol SpotifyManagerDelegate {
    func spotifyLoadingStarted()
    func spotifyLoginSucceeded()
    func spotifyLoginFailed(error: Error?)
}
