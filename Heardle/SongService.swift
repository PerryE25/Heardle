//
//  SongService.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/9/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

let db = Firestore.firestore()

class SongService {
    
    // Grab all default songs on Firestore and return a list of them
    func fetchDefaultSongs() async -> [Song] {
        do {
            let snapshot = try await db.collection("songs").getDocuments()

            var songs: [Song] = []

            for document in snapshot.documents {
                let data = document.data()

                if let name = data["name"] as? String,
                   let artist = data["artist"] as? String,
                   let album = data["album"] as? String,
                   let audioURL = data["audioURL"] as? String,
                   let albumArt = data["albumArt"] as? String,
                   let audio = URL(string: audioURL),
                   let art = URL(string: albumArt) {

                    songs.append(
                        Song(
                            name: name,
                            artist: artist,
                            album: album,
                            audioURL: audio,
                            albumArt: art
                        )
                    )
                }
            }

            return songs
        } catch {
            print(error)
            return []
        }
    }
    
    // Given the 7 impoprted songs that are in the project,
    // return them in a list
    func fetchImportSongs() -> [Song] {
        guard let thrillerURL = Bundle.main.url(forResource: "thriller_song", withExtension: "mp3") else { return [] }
        guard let billieJeanURL = Bundle.main.url(forResource: "billie_jean_song", withExtension: "mp3") else { return [] }
        guard let beatItURL = Bundle.main.url(forResource: "beat_it_song", withExtension: "mp3") else { return [] }
        guard let uptownFunkURL = Bundle.main.url(forResource: "uptown_funk", withExtension: "mp3") else { return [] }
        guard let haloURL = Bundle.main.url(forResource: "halo", withExtension: "mp3") else { return [] }
        guard let blindingLightsURL = Bundle.main.url(forResource: "blinding_lights", withExtension: "mp3") else { return  [] }
        guard let sunflowerURL = Bundle.main.url(forResource: "sunflower", withExtension: "mp3") else { return [] }

        guard let thrillerArt = getLocalImageURL(named: "thriller") else { return [] }
        guard let billieJeanArt = getLocalImageURL(named: "billie_jean") else { return [] }
        guard let beatItArt = getLocalImageURL(named: "beat_it") else { return [] }
        guard let uptownFunkArt = getLocalImageURL(named: "uptown_funk") else { return [] }
        guard let haloArt = getLocalImageURL(named: "halo") else { return [] }
        guard let blindingLightsArt = getLocalImageURL(named: "blinding_lights") else { return [] }
        guard let sunflowerArt = getLocalImageURL(named: "sunflower") else { return [] }
        
        songs = []

        songs.append(
            Song(
                name: "Thriller",
                artist: "Michael Jackson",
                album: "Thriller",
                audioURL: thrillerURL,
                albumArt: thrillerArt
            )
        )

        songs.append(
            Song(
                name: "Billie Jean",
                artist: "Michael Jackson",
                album: "Thriller",
                audioURL: billieJeanURL,
                albumArt: billieJeanArt
            )
        )

        songs.append(
            Song(
                name: "Beat It",
                artist: "Michael Jackson",
                album: "Thriller",
                audioURL: beatItURL,
                albumArt: beatItArt
            )
        )

        songs.append(
            Song(
                name: "Uptown Funk",
                artist: "Mark Ronson ft. Bruno Mars",
                album: "Uptown Special",
                audioURL: uptownFunkURL,
                albumArt: uptownFunkArt
            )
        )

        songs.append(
            Song(
                name: "Halo",
                artist: "Beyoncé",
                album: "I Am... Sasha Fierce",
                audioURL: haloURL,
                albumArt: haloArt
            )
        )

        songs.append(
            Song(
                name: "Blinding Lights",
                artist: "The Weeknd",
                album: "After Hours",
                audioURL: blindingLightsURL,
                albumArt: blindingLightsArt
            )
        )

        songs.append(
            Song(
                name: "Sunflower",
                artist: "Post Malone & Swae Lee",
                album: "Spider-Man: Into the Spider-Verse",
                audioURL: sunflowerURL,
                albumArt: sunflowerArt
            )
        )
        
        return songs
    }
    
    // given imageName, return URL of said image for uniformity.
    func getLocalImageURL(named imageName: String) -> URL? {
            guard let image = UIImage(named: imageName),
                  let data = image.pngData() else { return nil }
            
            // Create a unique temporary file URL
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(imageName).png")
            
            do {
                try data.write(to: tempURL)
                return tempURL
            } catch {
                print("Error saving image to URL: \(error)")
                return nil
            }
    }
}
