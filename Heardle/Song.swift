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
    
    var name: String
    var artist: String
    var album: String
    var audioURL: URL!
    var albumArt: URL!
    
    // Firebase Storage metadata
    var firebaseStorageAudioURL: URL?
    var firebaseStorageArtworkURL: URL?
    
    // iTunes metadata
    var trackId: Int?
    var genre: String?
    var previewURL: URL?
    var itunesArtworkURL: URL?
    
    // Initializes a Song with its metadata and associated media URLs.
    init(name: String, artist: String, album: String, audioURL: URL, albumArt: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.audioURL = audioURL
        self.albumArt = albumArt
    }
    
    // Firestore workaround for not having URL objects
    func toFirestore() -> [String: Any] {
            return [
                "name": name,
                "artist": artist,
                "album": album,
                "audioURL": audioURL.absoluteString,
                "albumArt": albumArt.absoluteString
            ]
        }
    
    // Initializes a Song with its firebase metadata and storage URLs.
    init(name: String, artist: String, album: String, firebaseStorageAudioURL: URL, firebaseStorageArtworkURL: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.firebaseStorageAudioURL = firebaseStorageAudioURL
        self.firebaseStorageArtworkURL = firebaseStorageArtworkURL
    }
    
    //Initialzes a Song with its iTunes metadata
    init(name: String, artist: String, album: String, trackId: Int, genre: String, previewURL: URL, itunesArtworkURL: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.trackId = trackId
        self.genre = genre
        self.previewURL = previewURL
        self.itunesArtworkURL = itunesArtworkURL
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
