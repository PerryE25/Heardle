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
    @IBOutlet weak var unlockPopup: UIView!
    @IBOutlet weak var unlockImage: UIImageView!
    @IBOutlet weak var unlockLabel: UILabel!
    
    // based on which attempt you're on is max
    // song time you can listen to
    let songTimes = [1, 2, 4, 7, 11, 16]

    var currentMaxTime: Int {
        songTimes[min(currentAttempts, songTimes.count - 1)]
    }
    
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
        
        guard let thrillerURL = Bundle.main.url(forResource: "thriller_song", withExtension: "mp3") else { return }
        guard let billieJeanURL = Bundle.main.url(forResource: "billie_jean_song", withExtension: "mp3") else { return }
        guard let beatItURL = Bundle.main.url(forResource: "beat_it_song", withExtension: "mp3") else { return }
        guard let uptownFunkURL = Bundle.main.url(forResource: "uptown_funk", withExtension: "mp3") else { return }
        guard let haloURL = Bundle.main.url(forResource: "halo", withExtension: "mp3") else { return }
        guard let blindingLightsURL = Bundle.main.url(forResource: "blinding_lights", withExtension: "mp3") else { return }
        guard let sunflowerURL = Bundle.main.url(forResource: "sunflower", withExtension: "mp3") else { return }

        guard let thrillerArt = getLocalImageURL(named: "thriller") else { return }
        guard let billieJeanArt = getLocalImageURL(named: "billie_jean") else { return }
        guard let beatItArt = getLocalImageURL(named: "beat_it") else { return }
        guard let uptownFunkArt = getLocalImageURL(named: "uptown_funk") else { return }
        guard let haloArt = getLocalImageURL(named: "halo") else { return }
        guard let blindingLightsArt = getLocalImageURL(named: "blinding_lights") else { return }
        guard let sunflowerArt = getLocalImageURL(named: "sunflower") else { return }

        songs = []
        prevGuesses = []

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
        

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        // edit popup
        unlockPopup.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)    // start small
        unlockPopup.alpha = 0.0   // start invisible
        unlockPopup.layer.cornerRadius = 15
        unlockLabel.alpha = 0.0
        
        currentAttempts = 0
        CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
        CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        CustomButton.rulesButtonConfig(rulesButton as! CustomButton)
        CustomButton.prevAttemptButtonConfig(prevAttemptsButton as! CustomButton)
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
    
    func displayPopup() {
        guard currentAttempts < 6 else { return }
        let addedTime = songTimes[currentAttempts] - songTimes[currentAttempts - 1]
        unlockLabel.text = "+\(addedTime)s unlocked!"
        
        // show popup
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
            
            // Wait until the shake finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.unlockImage.image = UIImage(systemName: "lock.open.fill")?
                        .withTintColor(.spotifyGreen, renderingMode: .alwaysOriginal)
                    self.unlockLabel.alpha = 1
                    self.unlockLabel.textColor = .spotifyGreen
                }) { _ in
                    
                    // Pause so the user can see it
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
                CustomButton.alreadyGuessSubmitConfig(submitButton as! CustomButton)
            } else {
                CustomButton.validGuessSubmitConfig(submitButton as! CustomButton)
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
            CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        }
    }
    
    deinit {
            // Always remove the time observer when the view controller is destroyed
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
        }
    
    // Error shake animation when guess wrong
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x - 10, y: mysteryAlbum.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x + 10, y: mysteryAlbum.center.y))
        mysteryAlbum.layer.add(animation, forKey: "position")
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
        let playerItem = AVPlayerItem(url: song.audioURL)
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
                
                // stop at max time like game play
                if Int(currentTimeSeconds) >= currentMaxTime {
                    CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
                    player.pause()
                    player.seek(to: .zero)

                    progressBar.setProgress(0, animated: false)
                    progressBar.progress = 0.0
                    currentTime.text = "00:00"
                }
                
//                maxTime.text = "String(format: "%02d:%02d", Int(durationSeconds/60), Int(durationSeconds.truncatingRemainder(dividingBy: 60)))"
                maxTime.text = String(format: "00:%02d", currentMaxTime)
                let max = Float64(truncating: currentMaxTime as NSNumber)
                // Calculate progress (Current Time / Total Duration)
                let progress = Float(currentTimeSeconds / max)
                
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
        displayPopup()
    }
    
    
    // Change play to pause and vice versa
    @IBAction func playButtonPressed(_ sender: Any) {
        // Pass this fileURL into your framework / function
        if playButton.imageView?.image == UIImage(systemName: "play.fill") {
            CustomButton.playButtonConfig(systemName: "pause.fill", playButton as! CustomButton)
            player?.play()
            

        } else {
            CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
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
        
        progressBar.progress = 0
        currentTime.text = "0:00"
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
            } else {
                shake()
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
