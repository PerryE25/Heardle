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
    //    var audioData: Data?
    var albumArtData: Data?
    
    // Firebase Storage metadata
    var firebaseStorageAudioURL: URL?
    var firebaseStorageArtworkURL: URL?
    
    // iTunes metadata
    var trackId: Int?
    var genre: String?
    var previewURL: String?
    var itunesArtworkURL: String?
    
    // Initializes only mandatory strings
    init(name: String, artist: String, album: String) {
        self.name = name
        self.artist = artist
        self.album = album
    }
    
    // Initializes a Song with its metadata and associated media URLs.
    init(name: String, artist: String, album: String, audioURL: URL, albumArt: URL) {
        self.name = name
        self.artist = artist
        self.album = album
        self.audioURL = audioURL
        self.albumArt = albumArt
    }
    
    //Initialzes a Song with its iTunes metadata
    init(name: String, artist: String, album: String, previewURL: String, itunesArtworkURL: String) {
        self.name = name
        self.artist = artist
        self.album = album
        self.previewURL = previewURL
        self.audioURL = URL(string: previewURL)
        self.albumArt = URL(string: itunesArtworkURL)
        self.itunesArtworkURL = itunesArtworkURL
    }
}

// Allows two Song objects to be compared for equality.
// Returns true when two songs have the same title and artist.
extension Song : Equatable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        // Normalize strings by removing extra whitespace and converting to lowercase
        let lhsName = lhs.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let rhsName = rhs.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lhsArtist = lhs.artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let rhsArtist = rhs.artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First check: exact match on normalized strings
        if lhsName == rhsName && lhsArtist == rhsArtist {
            return true
        }
        
        // Second check: normalize common variations in artist names
        // (ft., feat., featuring, &, etc.)
        let normalizedLhsArtist = normalizeArtistName(lhsArtist)
        let normalizedRhsArtist = normalizeArtistName(rhsArtist)
        
        return lhsName == rhsName && normalizedLhsArtist == normalizedRhsArtist
    }
    
    // Helper function to normalize artist names for better matching
    private static func normalizeArtistName(_ artist: String) -> String {
        var normalized = artist.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace common variations of "featuring"
        normalized = normalized.replacingOccurrences(of: " feat. ", with: " ft. ")
        normalized = normalized.replacingOccurrences(of: " feat ", with: " ft. ")
        normalized = normalized.replacingOccurrences(of: " featuring ", with: " ft. ")
        normalized = normalized.replacingOccurrences(of: " ft ", with: " ft. ")
        
        // Handle "&" vs "and"
        normalized = normalized.replacingOccurrences(of: " & ", with: " and ")
        
        // Remove extra spaces
        normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        
        return normalized
    }
}
