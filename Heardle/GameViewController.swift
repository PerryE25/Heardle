//
//  GameViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit
import AVFoundation

// A Game screen for playing one Heardle round
class GameViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rulesButton: UIButton!
    @IBOutlet weak var prevAttemptsButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var mysteryAlbum: UIImageView!
    @IBOutlet weak var mysteryAlbumCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextMysteryAlbum: UIImageView!
    @IBOutlet weak var nextMysteryAlbumCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var maxTime: UILabel!
    @IBOutlet weak var unlockSongButton: UIButton!
    @IBOutlet weak var skipSongButton: UIButton!
    @IBOutlet weak var selectedSong: UIView!
    @IBOutlet weak var songSearchBar: UISearchBar!
    
    // MARK: - Song sample setup
    var songs: [Song] = []
    var songIdx = 0
    
    
    // MARK: - Audio Properties
    var player: AVPlayer?
    var timeObserverToken: Any?
    
    // Add gradient with Sptofy's green
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard var aUrl = Bundle.main.url(forResource: "thriller_song", withExtension: "mp3") else { return }
        guard var bUrl = Bundle.main.url(forResource: "billie_jean_song", withExtension: "mp3") else { return }
        guard var cUrl = Bundle.main.url(forResource: "beat_it_song", withExtension: "mp3") else { return }
        guard let fURL = getLocalImageURL(named: "thriller") else {
            return
        }
        guard let gURL = getLocalImageURL(named: "billie_jean") else {
            return
        }
        guard let hURL = getLocalImageURL(named: "beat_it") else {
            return
        }
        do {
            let data = try Data(contentsOf: fURL)
            
        } catch { print(error) }
        var song2 = Song(name: "Thriller", artist: "Michael Jackson", album: "Thriller", audiuoURL: aUrl, albumArt: fURL)
        songs.append(song2)
        var song3 = Song(name: "Billie Jean", artist: "Michael Jackson", album: "Thriller", audiuoURL: bUrl, albumArt: gURL)
        songs.append(song3)
        var song1 = Song(name: "Beat It", artist: "Michael Jackson", album: "Thriller", audiuoURL: cUrl, albumArt: hURL)
        songs.append(song1)
        
        
        
        
        

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        CustomButton.playButtonConfig(systemName: "play.fill", playButton)
        CustomButton.noGuessSubmitConfig(submitButton)
        CustomButton.rulesButtonConfig(rulesButton)
        CustomButton.configPrevAttemptButton(prevAttemptsButton)
        selectedSong.layer.cornerRadius = 10
        selectedSong.layer.sublayers?[0].cornerRadius = 10
        songSearchBar.delegate = self
        
        updateOffScreenAlbum()
        setupAudioPlayer(song: songs[songIdx])
    }
    
    // make mystery album fade in
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // set the mystery albums initial alpha
        nextMysteryAlbum.alpha = 0.0
    }
    
    deinit {
            // Always remove the time observer when the view controller is destroyed
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
        }
    
    func setupAudioPlayer(song: Song) {
        
            // Replace with your local file name/type or a remote stream URL
//            guard let url = Bundle.main.url(forResource: "thriller_song", withExtension: "mp3") else {
//                print("Audio file not found")
//                return
//            }
            
            // Initialize AVPlayer and AVPlayerItem
        do {
            let data = try Data(contentsOf: song.albumArt)
//            mysteryAlbum.image = UIImage(data: data)
        } catch { print(error) }
        let playerItem = AVPlayerItem(url: song.audiuoURL)
            player = AVPlayer(playerItem: playerItem)
            
            // Reset progress view initially
            progressBar.progress = 0.0
            
            // Start observing playback progress
            addPlaybackObserver()
        }
    
    func addPlaybackObserver() {
            guard let player = player else { return }
            
            // Observe time every 0.5 seconds
            let interval = CMTime(value: 1, timescale: 2) // 0.5 seconds
            
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self, let currentItem = self.player?.currentItem else { return }
                
                // Get duration in seconds
                let durationSeconds = CMTimeGetSeconds(currentItem.duration)
                
                // Skip invalid durations
                guard durationSeconds.isFinite && durationSeconds > 0 else { return }
                
                // Get current playback time in seconds
                let currentTimeSeconds = CMTimeGetSeconds(time)
                currentTime.text = String(format: "%02d:%02d", Int(currentTimeSeconds/60), Int(currentTimeSeconds.truncatingRemainder(dividingBy: 60)))
//                if currentTimeSeconds >= 16 {
//                    player.pause()
//                }
                maxTime.text = String(format: "%02d:%02d", Int(durationSeconds/60), Int(durationSeconds.truncatingRemainder(dividingBy: 60)))
                
                // Calculate progress (Current Time / Total Duration)
                let progress = Float(currentTimeSeconds / durationSeconds)
                
                // Update UIProgressView
                self.progressBar.setProgress(progress, animated: true)
            }
        }
    
    // make the next mystery album to be on right side of screen
    func updateOffScreenAlbum() {
        let screenWidth = view.frame.width
        nextMysteryAlbumCenterXConstraint.constant = screenWidth
    }
    
    // Change play to pause and vice versa
    @IBAction func playButtonPressed(_ sender: Any) {
        // Pass this fileURL into your framework / function
        if playButton.imageView?.image == UIImage(systemName: "play.fill") {
            CustomButton.playButtonConfig(systemName: "pause.fill", playButton)
            player?.play()
            

        } else {
            CustomButton.playButtonConfig(systemName: "play.fill", playButton)
            player?.pause()
        }
    }
    
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

    
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        view.layoutIfNeeded()
        songIdx = (songIdx + 1) % songs.count
        
        
        // animate the alpha
        // and the center x constraints
        let screenWidth = view.frame.width
        self.nextMysteryAlbumCenterXConstraint.constant = 0
        self.mysteryAlbumCenterXConstraint.constant -= screenWidth
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            animations: {
                self.mysteryAlbum.alpha = 0.0
                self.nextMysteryAlbum.alpha = 1.0
                
                self.view.layoutIfNeeded()
            },
            completion: {_ in
                swap(&self.mysteryAlbum,
                     &self.nextMysteryAlbum)
                swap(&self.mysteryAlbumCenterXConstraint, &self.nextMysteryAlbumCenterXConstraint)
                
                self.updateOffScreenAlbum()
                
        })
        setupAudioPlayer(song: songs[songIdx])
    }
    
    // When searched, remove keyboard, like textfield return pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Touch outside of keyboard and keyboard is removed
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
