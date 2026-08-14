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
import FirebaseFirestore
import FirebaseAuth

// Shared song catalog (not per-game state).
var songs: [Song] = []
let songService = SongService()

// Controls one round of Heardle gameplay and manages game state, audio playback, and user interaction.
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
    
    var gameCode: String?
    private var session: GameSession = SoloSession(answerProvider: { songs[0] })
    
    // Track the history of correct songs from previous rounds.
    var matchResultHistory: [RoundResult] = []
    
    var currentSongIndex = 0
    var didWin = false
    var totalAttempts = 0
    var prevGuesses: [Song?] = []
    
    private var opponentAttempt = 0
    private var listener: ListenerRegistration?
    private var hasShownResults = false
    
    // Media player and observer.
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
    private var clipDurations: [Int] { session.clipDurations }
    
    var currentMaxTime: Int {
        clipDurations[min(currentAttempts, clipDurations.count - 1)]
    }
    
    let searchSegueID = "SearchSongSegue"
    let wrongGuessSegueID = "WrongGuessSegueID"
    let gameOverSegueID = "GameOverSegue"
    let duelResultSegueID = "duelResult"
    let prevAttemptsSegueID = "GameToPrevAttemptsSegueID"
    
    var currentAttempts = 0 {
        didSet {
            totalAttempts = currentAttempts
            
            // Everything below is UI work or a gameplay side effect —
            // only valid once the view exists.
            guard isViewLoaded else { return }
            
            prevAttemptsButton.setTitle(
                "Attempt \(currentAttempts) / \(session.maxAttempts) ", for: .normal)
            presentUnlockButton()
            
            session.recordAttempt(currentAttempts)
            
            if currentAttempts >= session.maxAttempts {
                finishRound(won: false)
            }
        }
    }
    
    // Sets up the game when the view is first loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioSession()
        prevGuesses = []
        if let gameCode {
            skipSongButton.isHidden = true
            Task {
                do {
                    let game = try await GameService.shared.fetchGame(code: gameCode)
                    self.session = MultiplayerSession(gameCode: gameCode, game: game)
                    self.startRound(from: game)
                    self.startObserving(code: gameCode)
                    self.currentAttempts = 0
                } catch {
                    print(error.localizedDescription)
                }
            }
        } else {
            // Pick a random song for solo play.
            if !songs.isEmpty {
                currentSongIndex = Int.random(in: 0..<songs.count)
            }
            
            session = SoloSession { [weak self] in
                guard let self = self, !songs.isEmpty else {
                    return songs.first ?? Song(name: "Unknown", artist: "Unknown", album: "Unknown")
                }
                return songs[self.currentSongIndex]
            }
            setupAudioPlayer(url: songs[currentSongIndex].audioURL)
        }
        
        styleScreen()
        currentAttempts = 0
        searchView.delegate = self
        updateOffScreenAlbum()
    }
    
    // Updates the game interface whenever the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nextMysteryAlbum.alpha = 0.0
        showSelectedSearch()
    }
    
    // Cleans up observers and listeners when the view controller is deallocated.
    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        listener?.remove()
    }
    
    // Allow real iPhone to play audio fine
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    // Starts a new multiplayer round using the provided game data.
    private func startRound(from game: Game) {
        guard let urlString = game.previewURL, let url = URL(string: urlString) else {
            return
        }
        
        setupAudioPlayer(url: url)
        maxTimeLabel.text = formatTime(Double(currentMaxTime))
    }
    
    // Begins listening for multiplayer game updates.
    private func startObserving(code: String) {
        listener = GameService.shared.observeGame(code: code) { [weak self] result in
            guard let self, case .success(let game) = result else { return }
            self.renderOpponent(game)
        }
    }
    
    // Updates the interface based on the opponent's current game state.
    private func renderOpponent(_ game: Game) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let opponentUID = (game.hostId == myUID) ? game.guestId : game.hostId
        guard let opponentUID else { return }
        
        opponentAttempt = game.playerAttempt[opponentUID] ?? 0
        
        // Handle different game states.
        switch game.status {
        case .roundResults, .finished:
            // One shot: segue to the results screen exactly once, then go
            // quiet. Without this, every later snapshot re-fires the segue
            // from this (now buried) instance — the "whose view is not in
            // the window hierarchy" spam and the phantom results screens.
            guard !hasShownResults else { break }
            hasShownResults = true
            listener?.remove()
            listener = nil
            player?.pause()
            performSegue(withIdentifier: duelResultSegueID, sender: game)
            
        case .playing:
            // Check if I'm done but opponent is still playing
            let myStatus = game.playerStatus[myUID]
            if myStatus != .playing {
                print("⏳ [GAME] Waiting for opponent to finish...")
                // TODO: Show "Waiting for opponent..." UI
            }
            
        default:
            break
        }
    }
    
    // Ends the current round and records the result.
    private func finishRound(won: Bool) {
        didWin = won
        session.recordFinish(won: won, attempts: currentAttempts)
        
        if gameCode == nil {
            // Solo: results immediately
            performSegue(withIdentifier: gameOverSegueID, sender: self)
        }
        // Multiplayer: wait for the listener to see status == .finished
        // TODO: show a "waiting for opponent" state here
    }
    
    // Converts a time interval into a minutes-and-seconds string.
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // Updates the player's point total in Firestore.
    private func updatePts() {
        let pts = 6 - currentAttempts
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            let data = snapshot?.data()
            let savedPts = data?["points"] as? Int ?? 0
            let newTotal = savedPts + pts
            
            userRef.updateData([
                "points": newTotal
            ]) { error in
                if let error = error {
                    print("Failed to update points: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Configures the audio player for the current song preview.
    private func setupAudioPlayer(url: URL) {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player = AVPlayer(playerItem: AVPlayerItem(url: url))
        progressBar.progress = 0.0
        addPlaybackObserver()
    }
    
    // Updates the playback progress while the song preview is playing.
    private func addPlaybackObserver() {
        guard let player else { return }
        let interval = CMTime(value: 1, timescale: 100)
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let currentItem = self.player?.currentItem else { return }
            
            let durationSeconds = CMTimeGetSeconds(currentItem.duration)
            guard durationSeconds.isFinite && durationSeconds > 0 else { return }
            
            let currentTimeSeconds = CMTimeGetSeconds(time)
            self.currentTimeLabel.text = self.formatTime(currentTimeSeconds)
            
            if Int(currentTimeSeconds) >= self.currentMaxTime {
                CustomButton.playButtonConfig(systemName: "play.fill", self.playButton as! CustomButton)
                player.pause()
                player.seek(to: .zero)
                self.progressBar.setProgress(0, animated: false)
                self.currentTimeLabel.text = self.formatTime(0)
            }
            
            self.maxTimeLabel.text = self.formatTime(Double(self.currentMaxTime))
            let progress = Float(currentTimeSeconds / Double(self.currentMaxTime))
            self.progressBar.setProgress(progress, animated: true)
        }
    }
    
    // Plays or pauses the current song preview.
    @IBAction func playButtonPressed(_ sender: Any) {
        if playButton.imageView?.image == UIImage(systemName: "play.fill") {
            CustomButton.playButtonConfig(systemName: "pause.fill", playButton as! CustomButton)
            player?.play()
        } else {
            CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
            player?.pause()
        }
    }
    
    // Unlocks additional playback time for the current song.
    @IBAction func unlockMore(_ sender: Any) {
        currentAttempts += 1
        displayPopup()
        maxTimeLabel.text = formatTime(Double(currentMaxTime))
        prevGuesses.append(nil)
    }
    
    // Updates the availability of the Unlock button.
    private func presentUnlockButton() {
        unlockSongButton.isUserInteractionEnabled = currentAttempts < session.maxAttempts - 1
    }
    
    // Skips the current song and starts a new round.
    @IBAction func skipButtonPressed(_ sender: Any) {
        guard session.allowsSkip else { return }
        
        view.layoutIfNeeded()
        currentAttempts = 0
        prevGuesses = []
        selectedSongCanidate = nil
        showSelectedSearch()
        currentSongIndex = (currentSongIndex + 1) % songs.count
        
        progressBar.progress = 0
        currentTimeLabel.text = formatTime(0)
        
        let screenWidth = view.frame.width
        nextMysteryAlbumCenterXConstraint.constant = 0
        mysteryAlbumCenterXConstraint.constant -= screenWidth
        UIView.animate(withDuration: 0.5, delay: 0, animations: {
            self.mysteryAlbum.alpha = 0.0
            self.nextMysteryAlbum.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            swap(&self.mysteryAlbum, &self.nextMysteryAlbum)
            swap(&self.mysteryAlbumCenterXConstraint, &self.nextMysteryAlbumCenterXConstraint)
            self.updateOffScreenAlbum()
        })
        
        maxTimeLabel.text = formatTime(Double(currentMaxTime))
        setupAudioPlayer(url: songs[currentSongIndex].audioURL)
    }
    
    // Submits the selected song as the player's guess.
    @IBAction func submitGuess(_ sender: Any) {
        if let answer = selectedSongCanidate {
            prevGuesses.append(answer)
            if session.isCorrect(answer) {
                finishRound(won: true)
                selectedSongCanidate = nil
                showSelectedSearch()
                return
            } else if currentAttempts < session.maxAttempts - 1 {
                shake()
                performSegue(withIdentifier: wrongGuessSegueID, sender: self)
            }
        }
        currentAttempts += 1
        maxTimeLabel.text = formatTime(Double(currentMaxTime))
        selectedSongCanidate = nil
        showSelectedSearch()
    }
    
    // Clears the currently selected song.
    @IBAction func dismissSelectedSong(_ sender: Any) {
        selectedSongCanidate = nil
        showSelectedSearch()
    }
    
    // Opens the song search screen.
    func searchViewDidTapSearch(_ searchView: SearchView) {
        performSegue(withIdentifier: searchSegueID, sender: self)
    }
    
    // Applies the initial appearance and styling for the game screen.
    private func styleScreen() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        unlockPopup.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        unlockPopup.alpha = 0.0
        unlockPopup.layer.cornerRadius = 15
        unlockLabel.alpha = 0.0
        
        CustomButton.playButtonConfig(systemName: "play.fill", playButton as! CustomButton)
        CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        CustomButton.rulesButtonConfig(rulesButton as! CustomButton)
        CustomButton.prevAttemptButtonConfig(prevAttemptsButton as! CustomButton)
        selectedSongCardView.layer.cornerRadius = 10
        selectedSongCardView.layer.sublayers?[0].cornerRadius = 10
        searchView.layer.cornerRadius = 10
    }
    
    // Positions the next album artwork off screen before the transition animation.
    private func updateOffScreenAlbum() {
        nextMysteryAlbumCenterXConstraint.constant = view.frame.width
    }
    
    // Updates the selected song display based on the current selection.
    private func showSelectedSearch() {
        if let chosenSong = selectedSongCanidate {
            selectedSongCardView.alpha = 1
            selectedSongCardView.subviews[3].isHidden = false
            (selectedSongCardView.subviews[1] as! UILabel).text = chosenSong.name
            (selectedSongCardView.subviews[2] as! UILabel).text = "\(chosenSong.artist)"
            if let data = chosenSong.albumArtData {
                (selectedSongCardView.subviews[0] as! UIImageView).image = UIImage(data: data)
            }
            if prevGuesses.contains(chosenSong) {
                CustomButton.alreadyGuessSubmitConfig(submitButton as! CustomButton)
            } else {
                CustomButton.validGuessSubmitConfig(submitButton as! CustomButton)
            }
        } else {
            selectedSongCardView.alpha = 0.35
            selectedSongCardView.subviews[3].isHidden = true
            (selectedSongCardView.subviews[1] as! UILabel).text = "Song Name"
            (selectedSongCardView.subviews[2] as! UILabel).text = "Artist"
            (selectedSongCardView.subviews[0] as! UIImageView).image = UIImage(systemName: "music.note")
            CustomButton.noGuessSubmitConfig(submitButton as! CustomButton)
        }
    }
    
    // Displays an animation when additional playback time is unlocked.
    private func displayPopup() {
        guard currentAttempts < session.maxAttempts, currentAttempts > 0 else { return }
        let addedTime = clipDurations[currentAttempts] - clipDurations[currentAttempts - 1]
        unlockLabel.text = "+\(addedTime)s unlocked!"
        
        UIView.animate(withDuration: 0.25, animations: {
            self.unlockPopup.transform = .identity
            self.unlockPopup.alpha = 1.0
            self.unlockImage.alpha = 1.0
            self.unlockLabel.textColor = .white
            self.unlockImage.image = UIImage(systemName: "lock")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
        }) { _ in
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.05
            animation.repeatCount = 2
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: self.unlockImage.center.x - 5, y: self.unlockImage.center.y))
            animation.toValue = NSValue(cgPoint: CGPoint(x: self.unlockImage.center.x + 5, y: self.unlockImage.center.y))
            self.unlockImage.layer.add(animation, forKey: "position")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.unlockImage.image = UIImage(systemName: "lock.open.fill")?
                        .withTintColor(.spotifyGreen, renderingMode: .alwaysOriginal)
                    self.unlockLabel.alpha = 1
                    self.unlockLabel.textColor = .spotifyGreen
                }) { _ in
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
    
    // Plays a shake animation for an incorrect guess.
    private func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x - 10, y: mysteryAlbum.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: mysteryAlbum.center.x + 10, y: mysteryAlbum.center.y))
        mysteryAlbum.layer.add(animation, forKey: "position")
    }
    
    // Configures destination view controllers before performing a segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case prevAttemptsSegueID:
            configurePreviousAttemptsSegue(for: segue)
        case wrongGuessSegueID:
            // Pass current attempts to WrongGuessViewController.
            if let wrongGuessVC = segue.destination as? WrongGuessViewController {
                wrongGuessVC.currentAttempts = currentAttempts + 1
            }
        case duelResultSegueID:
            prepareDuelResultsSegue(for: segue, sender: sender)
        case gameOverSegueID:
            prepareGameOverSegue(for: segue)
        default:
            break
        }
    }
    
    // Configures and presents the Previous Attempts sheet with a dynamic height.
    private func configurePreviousAttemptsSegue(for segue: UIStoryboardSegue) {
        if let sheetVC = segue.destination as? PreviousAttemptsViewController {
            sheetVC.validGuesses = prevGuesses.compactMap { $0 }
            if let sheet = sheetVC.sheetPresentationController {
                // Custom detents require iOS 16 or later.
                if #available(iOS 16.0, *) {
                    let dynamicDetent = UISheetPresentationController.Detent.custom { _ in
                        let rowHeight: CGFloat = 85
                        let headerHeight: CGFloat = 100
                        return (CGFloat(sheetVC.validGuesses.count) * rowHeight) + headerHeight
                    }
                    sheet.detents = [dynamicDetent, .large()]
                } else {
                    // default to middle or entire screen height if older than iOS 16.0
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(sheetVC, animated: true)
        }
    }
    
    // Configures and presents the Previous Attempts sheet with a dynamic height.
    private func prepareDuelResultsSegue(for segue: UIStoryboardSegue, sender: Any?) {
        updatePts()
        // Multiplayer - pass to DuelResultsViewController.
        if let game = sender as? Game, let resultsVC = segue.destination as? DuelResultsViewController {
            resultsVC.gameCode = gameCode
            resultsVC.didWin = didWin
            resultsVC.myAttempts = currentAttempts
            resultsVC.prevGuesses = prevGuesses.compactMap { $0 }
            
            // Set round info.
            resultsVC.currentRound = game.currentRound ?? 1
            resultsVC.totalRounds = game.totalRounds ?? 1
            resultsVC.isGameComplete = (game.status == .finished)
            
            // Get my and opponent scores.
            if let myUID = Auth.auth().currentUser?.uid {
                // Round wins - who won each round
                resultsVC.myRoundsWon = game.playerRoundsWon?[myUID] ?? 0
                
                let opponentUID = (game.hostId == myUID) ? game.guestId : game.hostId
                if let opponentUID = opponentUID {
                    resultsVC.opponentRoundsWon = game.playerRoundsWon?[opponentUID] ?? 0
                    resultsVC.opponentAttempts = game.playerAttempt[opponentUID] ?? 0
                }
            }
            
            // Resolve the round's answer from the shared catalog by
            // trackId so the results screen gets real album artwork;
            // fall back to a bare title/artist Song if it's missing.
            var roundSong: Song?
            if let targetId = game.trackId {
                roundSong = songs.first { song in
                    guard let id = song.trackId else { return false }
                    return String(id) == targetId
                }
            }
            if roundSong == nil, let trackTitle = game.trackTitle, let trackArtist = game.trackArtist {
                roundSong = Song(name: trackTitle, artist: trackArtist, album: "")
            }
            if let roundSong {
                resultsVC.correctSong = roundSong
            }
            
            // Pass the match breakdown history from previous rounds.
            resultsVC.matchResultList = matchResultHistory
        }
    }
    
    // Passes solo game results to the SoloGameResultsViewController.
    private func prepareGameOverSegue(for segue: UIStoryboardSegue) {
        // Solo game - pass to SoloGameResultsViewController.
        updatePts()
        if let resultsVC = segue.destination as? SoloGameResultsViewController {
            resultsVC.didWin = didWin
            resultsVC.totalAttempts = totalAttempts
            resultsVC.clipDurations = clipDurations
            
            // Pass the current song
            if !songs.isEmpty && currentSongIndex < songs.count {
                resultsVC.currentSong = songs[currentSongIndex]
            }
        }
    }
}
