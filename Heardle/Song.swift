//
//  Song.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/3/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

// Represents a song and stores its identifying information and media URLs.
class Song {
    
    var id = UUID()
    
    var name: String
    var artist: String
    var album: String
    var audioURL: URL
    var albumArt: URL
    
    // Initializes a Song with its metadata and associated media URLs.
    init(name: String, artist: String, album: String, audioURL: URL, albumArt: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.audioURL = audioURL
        self.albumArt = albumArt
    }
}

// Allows two Song objects to be compared for equality.
// Returns true when two songs have the same title and artist.
extension Song : Equatable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        // two songs are the same if they have the same name/artist
        return lhs.name.lowercased() == rhs.name.lowercased() && lhs.artist.lowercased() == rhs.artist.lowercased()
    }
}
