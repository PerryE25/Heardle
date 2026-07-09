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

// A class for song metadata
class Song {
    
    var id: UUID = UUID()
    
    var name: String
    var artist: String
    var album: String
    var audiuoURL: URL
    var albumArt: URL
    
    init(name: String, artist: String, album: String, audiuoURL: URL, albumArt: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.audiuoURL = audiuoURL
        self.albumArt = albumArt
    }
}

// Like the Java Comparator interface for equating two objects
extension Song : Equatable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        // two songs are the same if they have the same name/artist
        return lhs.name.lowercased() == rhs.name.lowercased() && lhs.artist.lowercased() == rhs.artist.lowercased()
    }
}
