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
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import MusicKit

let db = Firestore.firestore()
let storage = Storage.storage()

class SongService {

    func fetchSongsForCurrentUser() async -> [Song] {
        if let user = Auth.auth().currentUser {
            let userDocument = db.collection("users").document(user.uid)

            do {
                let snapshot = try await userDocument.getDocument()
                let data = snapshot.data()
                let spotifyConnected =
                    data?["spotifyConnected"] as? Bool ?? false
                let songsImported =
                    data?["songsImported"] as? Bool ?? false

                if spotifyConnected && songsImported {
                    let userSongs = await fetchUserSongs(userID: user.uid)

                    if !userSongs.isEmpty {
                        print("Loaded \(userSongs.count) Spotify songs")
                        return userSongs
                    }
                }
            } catch {
                print("Could not check user songs: \(error.localizedDescription)")
            }
        }

        let defaultSongs = await fetchDefaults()
        await updateAlbumArtData(songs: defaultSongs)
        print("Loaded \(defaultSongs.count) default songs")
        return defaultSongs
    }

    func fetchUserSongs(userID: String) async -> [Song] {
        do {
            let snapshot = try await db
                .collection("users")
                .document(userID)
                .collection("songs")
                .order(by: "order")
                .getDocuments()

            var userSongs: [Song] = []

            var docIdx = 0
            for document in snapshot.documents {
                let data = document.data()

                print("docidx is \(docIdx)")
                print("name is \(data["name"] ?? "nil name"), artist is \(data["artist"] ?? "nil artist"), album is \(data["album"] ?? "nil album"), audioURL is \(data["audioURL"] ?? "nil"), albumArt is \(data["albumArt"] ?? "nil")")
                
                guard
                    let name = data["name"] as? String,
                    let artist = data["artist"] as? String,
                    let album = data["album"] as? String,
                    let audioURLString = data["audioURL"] as? String,
                    let albumArtString = data["albumArt"] as? String,
                    !albumArtString.isEmpty,
                    let audioURL = URL(string: audioURLString),
                    let albumArtURL = URL(string: albumArtString),
                    let albumArtData = try? await downloadData(
                        from: albumArtString
                    )
                else {
                    continue
                }

                let song = Song(
                    name: name,
                    artist: artist,
                    album: album,
                    audioURL: audioURL,
                    albumArt: albumArtURL
                )
                song.previewURL = audioURLString
                song.itunesArtworkURL = albumArtString
                song.albumArtData = albumArtData
                
                // Load trackId if available from Firebase
                if let trackId = data["trackId"] as? Int {
                    song.trackId = trackId
                } else {
                    // Generate a synthetic trackId from song name + artist for multiplayer compatibility
                    // This creates a consistent ID even if iTunes trackId isn't available
                    let combinedString = "\(name.lowercased())-\(artist.lowercased())"
                    let hashValue = abs(combinedString.hashValue)
                    song.trackId = hashValue
                    print("Generated trackId \(hashValue) for \(name) by \(artist)")
                }
                
                userSongs.append(song)
            }

            return userSongs
        } catch {
            print("Could not load user songs: \(error.localizedDescription)")
            return []
        }
    }
    
    // Grab all default songs on Firestore and return a list of them
    func fetchDefaults() async -> [Song] {
        do {
            let snapshot = try await db.collection("defaults").getDocuments()
            
            var songs: [Song] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                if let name = data["name"] as? String,
                   let artist = data["artist"] as? String,
                   let album = data["album"] as? String {
                    let curSong = Song(name: name, artist: artist, album: album)
                    await fetchArtworkAndPreview(song: curSong)
                    
                    // Generate synthetic trackId if not set by iTunes
                    if curSong.trackId == nil {
                        let combinedString = "\(name.lowercased())-\(artist.lowercased())"
                        let hashValue = abs(combinedString.hashValue)
                        curSong.trackId = hashValue
                        print("Generated trackId \(hashValue) for default song \(name) by \(artist)")
                    }
                    
                    songs.append(curSong)
                }
            }
            
            return songs
        } catch {
            print(error)
            return []
        }
    }
    
    // Given user's top 100 songs, fetch the album covers and artwork
    func fetchUsersArtworkAndPreview(songs: [Song]) async {
        for curSong in songs {
            await fetchArtworkAndPreview(song: curSong)
        }
    }
    
    // Given api artwork url, download data of all songs
    func updateAlbumArtData() async {
        await updateAlbumArtData(songs: songs)
    }
    
    // Given api artwork url, download data of all songs
    func updateAlbumArtData(songs: [Song]) async {
        for curSong in songs {
            guard let artworkURL = curSong.itunesArtworkURL else {
                continue
            }

            do {
                curSong.albumArtData = try await downloadData(from: artworkURL)
            } catch {
                print(error)
            }
        }
    }
    
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
                    
                    let albumArtData = try await downloadData(from: albumArt)
                    let curSong = Song(
                        name: name,
                        artist: artist,
                        album: album,
                        audioURL: audio,
                        albumArt: art
                    )
                    curSong.albumArtData = albumArtData
                    songs.append(curSong)
                }
            }
            
            return songs
        } catch {
            print(error)
            return []
        }
    }
    
    // Given search term, return top 25 songs similar to an iTunes search
    func searchForSongs(searchTerm: String) async -> [Song] {
        let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://itunes.apple.com/search?term=\(encodedSearchTerm)&entity=song&limit=25"
        
        guard let url = URL(string: searchURL) else { return [] }
        var songResults: [Song] = []
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                for result in results {
                    let name = result["trackName"] as? String ?? ""
                    let artist = result["artistName"] as? String ?? ""
                    let album = result["collectionName"] as? String ?? ""
                    let prevUrl = result["previewUrl"] as? String ?? ""
                    let artworkUrl = result["artworkUrl100"] as? String ?? ""
                    
                    let song = Song(name: name, artist: artist, album: album, previewURL: prevUrl, itunesArtworkURL: artworkUrl)
                    
                    // Try to get real trackId from iTunes, or generate synthetic one
                    if let trackId = result["trackId"] as? Int {
                        song.trackId = trackId
                    } else {
                        let combinedString = "\(name.lowercased())-\(artist.lowercased())"
                        song.trackId = abs(combinedString.hashValue)
                    }
                    
                    songResults.append(song)
                }
            }
        } catch {
            print(error)
        }
        
        return songResults
    }
    
    // Grab song's artwork and previewAudio given song name and artist name
    func fetchArtworkAndPreview(song: Song) async {
        let searchTerm = "\(song.name) \(song.artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let searchURL = "https://itunes.apple.com/search?term=\(searchTerm)&entity=song&limit=1"

        guard let url = URL(string: searchURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            print("search url is \(searchURL)")
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first {

                print(json["resultCount"] ?? "none")
                song.itunesArtworkURL = first["artworkUrl100"] as? String
                // make high resolution for large album display
                song.itunesArtworkURL = song.itunesArtworkURL?.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                song.previewURL = first["previewUrl"] as? String

                if let preview = song.previewURL {
                    song.audioURL = URL(string: preview)
                }
                
                // Try to get trackId from iTunes, or generate synthetic one
                if let trackId = first["trackId"] as? Int {
                    song.trackId = trackId
                } else {
                    // Generate synthetic trackId for multiplayer compatibility
                    let combinedString = "\(song.name.lowercased())-\(song.artist.lowercased())"
                    let hashValue = abs(combinedString.hashValue)
                    song.trackId = hashValue
                    print("Generated synthetic trackId \(hashValue) for \(song.name)")
                }
            } else {
                // No iTunes results - still generate synthetic ID
                let combinedString = "\(song.name.lowercased())-\(song.artist.lowercased())"
                let hashValue = abs(combinedString.hashValue)
                song.trackId = hashValue
                print("No iTunes result - Generated trackId \(hashValue) for \(song.name)")
            }
        } catch {
            print(error)
            // On error, still generate synthetic ID
            let combinedString = "\(song.name.lowercased())-\(song.artist.lowercased())"
            let hashValue = abs(combinedString.hashValue)
            song.trackId = hashValue
        }
    }
    
    // Helps bg process of image/audio downlaods
    func downloadData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    // Based on given song, return artwork (handle url retrieval)
    //    func getAudio(of: Song) -> URL? {
    //
    //    }
    
    // Based on given song, return preview audio (handle url retrieval)
    //    func getPreview(of: Song) -> UIImage? {
    //
    //    }
    
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
