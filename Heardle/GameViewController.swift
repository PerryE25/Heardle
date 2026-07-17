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

// Current mystery song, win status and attempts needed to win/lose for results screen
var songs: [Song] = []
var currentSongIndex = 0
var didWin: Bool = false
var globalTotalAttempts: Int = 0
let songService = SongService()

// Controls one round of Heardle gameplay. Manages audio playback limits per attempt
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
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var unlockSongButton: UIButton!
    @IBOutlet weak var skipSongButton: UIButton!
    @IBOutlet weak var selectedSongCardView: UIView!
    @IBOutlet weak var searchView: SearchView!
    @IBOutlet weak var unlockPopup: UIView!
    @IBOutlet weak var unlockImage: UIImageView!
    @IBOutlet weak var unlockLabel: UILabel!
    
    // Per-attempt time gates (in seconds) that cap how long the sample may play.
    let songTimes = [1, 2, 4, 7, 11, 16]

    // Current playback cap derived from the attempt count and time gates.
    var currentMaxTime: Int {
        songTimes[min(currentAttempts, songTimes.count - 1)]
    }
    
    let searchSegueID = "SearchSongSegue"
    let wrongGuessSegueID = "WrongGuessSegueID"
    let gameOverSegueID = "GameOverSegue"
    
    // Tracks the player's attempt count and triggers game over on the sixth attempt.
    var currentAttempts = 0 {
        didSet {
            globalTotalAttempts = currentAttempts
            prevAttemptsButton.setTitle("Attempt \(currentAttempts) / 6 ", for: .normal)
            if self.currentAttempts == 6 {
                print("final results are didWin: \(didWin), globalAttempts: \(globalTotalAttempts), current song name is: \(songs[currentSongIndex].name)")
                performSegue(withIdentifier: gameOverSegueID, sender: self)
            }
        }
    }
    
    // Keeps a history of submitted guesses to prevent duplicates and drive UI state.
    var prevGuesses: [Song] = []
    
    // Primary audio player for song samples during a round.
    // Token used to remove the periodic time observer when deinitializing.
    var player: AVPlayer?
    var timeObserverToken: Any?
    
    // Prepares the round: loads local demo songs, configures UI/gradient, sets delegates,
    // and initializes the audio player and attempt state.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prevGuesses = []
//        Task {
//            songs = await songService.fetchDefaults()
//            await songService.updateAlbumArtData()
//            //                songs = songService.fetchImportSongs()
//            
//            print("Fetched \(songs.count) songs")
//            
//            guard !songs.isEmpty else {
//                print("No songs found")
//                return
//            }
//            
//            
//        }
        setupAudioPlayer(song: songs[currentSongIndex])
        
        // Background gradient styled similar to Spotify’s player.
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        // Initialize unlock popup appearance and animation baseline.
        unlockPopup.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)    // start small
        unlockPopup.alpha = 0.0   // start invisible
        unlockPopup.layer.cornerRadius = 15
        unlockLabel.alpha = 0.0
        
        currentAttempts = 0
        CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
        CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        CustomButton.rulesButtonConfig(rulesButton as! CustomButton)
        CustomButton.prevAttemptButtonConfig(prevAttemptsButton as! CustomButton)
        selectedSongCardView.layer.cornerRadius = 10
        selectedSongCardView.layer.sublayers?[0].cornerRadius = 10
        searchView.delegate = self
        updateOffScreenAlbum()
//        setupAudioPlayer(song: songs[currentSongIndex])
    }
    
    // Update the user's song selection and make nextAlbum invisible
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nextMysteryAlbum.alpha = 0.0
        showSelectedSearch()
    }
    
    // Formats seconds into mm:ss (e.g., 0 -> "00:00").
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // Configures AVPlayer for the given song and prepares progress observation.
    func setupAudioPlayer(song: Song) {
        let playerItem = AVPlayerItem(url: song.audioURL)
        player = AVPlayer(playerItem: playerItem)

        // Reset progress view initially
        progressBar.progress = 0.0
        
        // Start observing playback progress
        addPlaybackObserver()
    }
    
    // Observes playback time to update UI, enforce per-attempt limits, and reset when capped.
    func addPlaybackObserver() {
        guard let player = player else { return }
        
        // Poll playback twice per second for smooth progress updates.
        let interval = CMTime(value: 1, timescale: 2) // 0.5 seconds
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem else { return }
            
            // Retrieve media duration in seconds.
            let durationSeconds = CMTimeGetSeconds(currentItem.duration)
            
            // Ignore unknown or invalid durations.
            guard durationSeconds.isFinite && durationSeconds > 0 else { return }
            
            // Current playback time (seconds).
            let currentTimeSeconds = CMTimeGetSeconds(time)
            currentTimeLabel.text = formatTime(currentTimeSeconds)
            
            // Enforce the current attempt’s playback cap and reset player/UI.
            if Int(currentTimeSeconds) >= currentMaxTime {
                CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
                player.pause()
                player.seek(to: .zero)

                progressBar.setProgress(0, animated: false)
                progressBar.progress = 0.0
                currentTimeLabel.text = formatTime(0)
            }
            
            maxTimeLabel.text = formatTime(Double(currentMaxTime))
            
            // Compute progress relative to the allowed cap, not the full track.
            let max = Float64(truncating: currentMaxTime as NSNumber)
            let progress = Float(currentTimeSeconds / max)
            
            // Animate progress bar to reflect elapsed allowed time.
            self.progressBar.setProgress(progress, animated: true)
        }
    }
    
    // Positions the next album image off-screen to the right in preparation for slide-in.
    func updateOffScreenAlbum() {
        let screenWidth = view.frame.width
        nextMysteryAlbumCenterXConstraint.constant = screenWidth
    }
    
    // Reflects the currently chosen song in the summary card and updates submit state.
    private func showSelectedSearch() {
        
        if let chosenSong = selectedSongCanidate {
            selectedSongCardView.alpha = 1
            selectedSongCardView.subviews[3].isHidden = false
            let songLabel = selectedSongCardView.subviews[1] as! UILabel
            songLabel.text = chosenSong.name
            let albumLabel = selectedSongCardView.subviews[2] as! UILabel
            albumLabel.text = "\(chosenSong.artist)"
            let imageView = selectedSongCardView.subviews[0] as! UIImageView
            imageView.image = UIImage(data: chosenSong.albumArtData!)
            if prevGuesses.contains(chosenSong) {
                CustomButton.alreadyGuessSubmitConfig(submitButton as! CustomButton)
            } else {
                CustomButton.validGuessSubmitConfig(submitButton as! CustomButton)
            }
            
        } else {
            selectedSongCardView.alpha = 0.35
            selectedSongCardView.subviews[3].isHidden = true
            let songLabel = selectedSongCardView.subviews[1] as! UILabel
            songLabel.text = "Song Name"
            let albumLabel = selectedSongCardView.subviews[2] as! UILabel
            albumLabel.text = "Artist"
            let imageView = selectedSongCardView.subviews[0] as! UIImageView
            imageView.image = UIImage(systemName: "music.note")
            CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        }
    }
    
    // Animates the "time unlocked" popup to communicate newly granted playback seconds.
    func displayPopup() {
        guard currentAttempts < 6 else { return }
        let addedTime = songTimes[currentAttempts] - songTimes[currentAttempts - 1]
        unlockLabel.text = "+\(addedTime)s unlocked!"
        
        // Present and scale-in the popup.
        UIView.animate(withDuration: 0.25, animations: {
            self.unlockPopup.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.unlockPopup.alpha = 1.0
            self.unlockImage.alpha = 1.0
            self.unlockLabel.textColor = .white
            self.unlockImage.image = UIImage(systemName: "lock")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            
        }) { _ in
            
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.05
            animation.repeatCount = 2
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: self.unlockImage.center.x - 5, y: self.unlockImage.center.y))
            animation.toValue = NSValue(cgPoint: CGPoint(x: self.unlockImage.center.x + 5, y: self.unlockImage.center.y))
            self.unlockImage.layer.add(animation, forKey: "position")
            
            // Defer until the lock shake completes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.unlockImage.image = UIImage(systemName: "lock.open.fill")?
                        .withTintColor(.spotifyGreen, renderingMode: .alwaysOriginal)
                    self.unlockLabel.alpha = 1
                    self.unlockLabel.textColor = .spotifyGreen
                }) { _ in
                    
                    // Briefly hold the unlocked state before dismissing.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        
                        UIView.animate(withDuration: 0.3) {
                            self.unlockPopup.alpha = 0
                            self.unlockPopup.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                        }
                    }
                }
            }
        }
    }
    
    // Provides a subtle error feedback by shaking the album art on incorrect guesses.
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x - 10, y: mysteryAlbum.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x + 10, y: mysteryAlbum.center.y))
        mysteryAlbum.layer.add(animation, forKey: "position")
    }
    
    // Navigates to the search screen when the embedded search view is tapped.
    func searchViewDidTapSearch(_ searchView: SearchView) {
        performSegue(withIdentifier: searchSegueID, sender: self)
    }
    
    // MARK: - Actions

    // Toggles playback and updates the play/pause button configuration.
    @IBAction func playButtonPressed(_ sender: Any) {
        if playButton.imageView?.image == UIImage(systemName: "play.fill") {
            CustomButton.playButtonConfig(systemName: "pause.fill", playButton as! CustomButton)
            player?.play()
        } else {
            CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
            player?.pause()
        }
    }
    
    // Increments attempt count and shows the unlock feedback popup.
    @IBAction func unlockMore(_ sender: Any) {
        currentAttempts += 1
        displayPopup()
    }
    
    // Skips to the next song, animating the album art transition and resetting state.
    @IBAction func skipButtonPressed(_ sender: Any) {
        view.layoutIfNeeded()
        currentAttempts = 0
        selectedSongCanidate = nil
        showSelectedSearch()
        currentSongIndex = (currentSongIndex + 1) % songs.count
        
        progressBar.progress = 0
        currentTimeLabel.text = formatTime(0)
        
        // Fade out current art, fade in next, and slide constraints to transition.
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
        setupAudioPlayer(song: songs[currentSongIndex])
    }
    
    // Submits the current guess, checks correctness, provides feedback, and advances attempts.
    @IBAction func submitGuess(_ sender: Any) {
        if let answer = selectedSongCanidate {
            // Added by Jeremiah in order to keep track of if the user has already guessed a song so it doesnt count towards the currentAttempts total that is used in the WrongGuessesVC (Not sure we keep this in or not)
            for guess in prevGuesses where guess == answer {
                shake()
                performSegue(withIdentifier: wrongGuessSegueID, sender: self)
                return
            }
            
            prevGuesses.append(answer)
            if answer == songs[currentSongIndex] {
                didWin = true
                performSegue(withIdentifier: "GameOverSegue", sender: self)
            } else {
                shake()
            }
        }
        currentAttempts += 1
        selectedSongCanidate = nil
        showSelectedSearch()
        
    }
    
    // Clears the current selection from the summary card.
    @IBAction func dismissSelectedSong(_ sender: Any) {
        selectedSongCanidate = nil
        showSelectedSearch()
    }
    
    // Cleans up playback observation when the controller is deallocated.
    deinit {
        // Detach the periodic time observer to avoid leaks/crashes.
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
}

