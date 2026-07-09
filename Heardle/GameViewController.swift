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

var songs: [Song] = []

// A Game screen for playing one Heardle round
class GameViewController: UIViewController, SearchViewDelegate {
    
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
    @IBOutlet weak var searchView: SearchView!
    
    let searchSegueID = "SearchSongSegue"
    var currentAttempts = 0 {
        didSet {
            prevAttemptsButton.setTitle("Attempt \(currentAttempts) / 6 ", for: .normal)
            if self.currentAttempts == 6 {
                performSegue(withIdentifier: "GameOverSegue", sender: self)
            }
        }
    }
    var prevGuesses: [Song] = []
    
    // MARK: - Song sample setup
    
    var songIdx = 0
    
    
    // MARK: - Audio Properties
    var player: AVPlayer?
    var timeObserverToken: Any?
    
    // Add gradient with Sptofy's green
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let aUrl = Bundle.main.url(forResource: "thriller_song", withExtension: "mp3") else { return }
        guard let bUrl = Bundle.main.url(forResource: "billie_jean_song", withExtension: "mp3") else { return }
        guard let cUrl = Bundle.main.url(forResource: "beat_it_song", withExtension: "mp3") else { return }
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
        
        songs = []
        prevGuesses = []
        let song2 = Song(name: "Thriller", artist: "Michael Jackson", album: "Thriller", audiuoURL: aUrl, albumArt: fURL)
        songs.append(song2)
        let song3 = Song(name: "Billie Jean", artist: "Michael Jackson", album: "Thriller", audiuoURL: bUrl, albumArt: gURL)
        songs.append(song3)
        let song1 = Song(name: "Beat It", artist: "Michael Jackson", album: "Thriller", audiuoURL: cUrl, albumArt: hURL)
        songs.append(song1)
        

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        currentAttempts = 0
        CustomButton.playButtonConfig(systemName: "play.fill", playButton)
        CustomButton.noGuessSubmitConfig(submitButton)
        CustomButton.rulesButtonConfig(rulesButton)
        CustomButton.configPrevAttemptButton(prevAttemptsButton)
        selectedSong.layer.cornerRadius = 10
        selectedSong.layer.sublayers?[0].cornerRadius = 10
        searchView.delegate = self
        updateOffScreenAlbum()
        setupAudioPlayer(song: songs[songIdx])
    }
    
    // make mystery album fade in
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // set the mystery albums initial alpha
        nextMysteryAlbum.alpha = 0.0
        showSelectedSearch()
    }
    
    // Show the selected search and update submit button accordingly
    // submit can be not present or valid or already guessed
    private func showSelectedSearch() {
        if let chosenSong = selectedSearch {
            selectedSong.alpha = 1
            selectedSong.subviews[3].isHidden = false
            let songLabel = selectedSong.subviews[1] as! UILabel
            songLabel.text = chosenSong.name
            let albumLabel = selectedSong.subviews[2] as! UILabel
            albumLabel.text = "\(chosenSong.artist)"
            let imageView = selectedSong.subviews[0] as! UIImageView
            do {
                let data = try Data(contentsOf: chosenSong.albumArt)
                let img = UIImage(data: data)
                imageView.image = img
            } catch { print(error) }
            if prevGuesses.contains(chosenSong) {
                CustomButton.alreadyGuessSubmitConfig(submitButton)
            } else {
                CustomButton.validGuessSubmitConfig(submitButton)
            }
            
        } else {
            selectedSong.alpha = 0.35
            selectedSong.subviews[3].isHidden = true
            let songLabel = selectedSong.subviews[1] as! UILabel
            songLabel.text = "Song Name"
            let albumLabel = selectedSong.subviews[2] as! UILabel
            albumLabel.text = "Artist"
            let imageView = selectedSong.subviews[0] as! UIImageView
            imageView.image = UIImage(systemName: "music.note")
            CustomButton.noGuessSubmitConfig(submitButton)
        }
    }
    
    deinit {
            // Always remove the time observer when the view controller is destroyed
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
        }
    
    // Will search after pressing this button
    func searchViewDidTapSearch(_ searchView: SearchView) {
//        let searchVC = SearchViewController()
//        navigationController?.pushViewController(searchVC, animated: true)
        performSegue(withIdentifier: searchSegueID, sender: self)
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
    
    
    @IBAction func unlockMore(_ sender: Any) {
        currentAttempts += 1
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
        currentAttempts = 0
        selectedSearch = nil
        showSelectedSearch()
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
    
    
    @IBAction func submitGuess(_ sender: Any) {
        if let answer = selectedSearch {
            prevGuesses.append(answer)
            if answer == songs[songIdx] {
                performSegue(withIdentifier: "GameOverSegue", sender: self)
            }
        }
        currentAttempts += 1
        selectedSearch = nil
        showSelectedSearch()
        
    }
    
    @IBAction func dismissSelectedSong(_ sender: Any) {
        selectedSearch = nil
        showSelectedSearch()
    }
    
}
