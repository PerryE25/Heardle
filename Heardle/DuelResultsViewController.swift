//
//  DuelResultsViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// Represents the result of one completed round, including the song played and both players' scores.
struct RoundResult {
    let song: Song
    let myScore: Int
    let opponentScore: Int
}

// Stores and displays duel results, manages round transitions, tracks opponent readiness,
// and shows the match history between players.
class DuelResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var player1Score: UILabel!
    @IBOutlet weak var player1ScoreSmall: UILabel!
    @IBOutlet weak var player2ScoreSmall: UILabel!
    @IBOutlet weak var continueButtonLabel: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var pointsEarnedLabel: UILabel!
    @IBOutlet weak var matchBreakdownView: UIStackView!
    @IBOutlet weak var resultScoreView: UIStackView!
    
    var gameCode: String?
    var didWin = false
    var myAttempts = 0
    var opponentAttempts = 0
    var prevGuesses: [Song] = []
    var correctSong: Song?
    
    var currentRound = 1
    var totalRounds = 1
    var isGameComplete = false
    
    var myRoundsWon = 0
    var opponentRoundsWon = 0
    
    // Stores the list of songs and scores from completed rounds for the match breakdown display.
    var matchResultList: [RoundResult] = []
    
    // Provides the current player's total round wins.
    var player1ScoreValue: Int { myRoundsWon }
    
    // Provides the opponent's total round wins.
    var player2ScoreValue: Int { opponentRoundsWon }
    
    let textCellIdentifier = "TextCell"
    
    private var listener: ListenerRegistration?
    private var autoContinueTimer: Timer?
    private let autoContinueDelay: TimeInterval = 10.0
    private var opponentReady = false
    private var hasMarkedReady = false
    private var hasTransitioned = false
    
    // Configures the results screen, initializes table view delegates,
    // updates UI styling, starts multiplayer observers, and begins automatic continuation handling.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        matchBreakdownView.layer.borderWidth = 1
        matchBreakdownView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        resultScoreView.layer.borderWidth = 1
        resultScoreView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        
        // Add the correct song from this round to the match breakdown
        if let correctSong = correctSong {
            print("[DUEL RESULTS] Adding correct song to breakdown: \(correctSong.name) by \(correctSong.artist)")
            matchResultList.append(RoundResult(song: correctSong,
                                               myScore: myRoundsWon,
                                               opponentScore: opponentRoundsWon))
            print("[DUEL RESULTS] Total songs in breakdown: \(matchResultList.count)")
        } else {
            print("[DUEL RESULTS] No correct song provided for this round")
        }
        
        // Print all songs in the breakdown
        print("[DUEL RESULTS] Current match breakdown:")
        for (index, entry) in matchResultList.enumerated() {
            print("   Round \(index + 1): \(entry.song.name) by \(entry.song.artist) — \(entry.myScore)-\(entry.opponentScore)")
        }
        
        // Reset transition flag for new round
        hasTransitioned = false
        
        configureButtonVisibility()
        
        if let gameCode {
            startObserving(code: gameCode)
        }
        
        updateContinueButton()
        
        if !isGameComplete {
            startAutoContinueTimer()
        }
    }
    
    // Removes active listeners and invalidates timers when the view controller is released.
    deinit {
        listener?.remove()
        autoContinueTimer?.invalidate()
    }
    
    // Updates button visibility based on whether the duel has ended or another round can continue.
    private func configureButtonVisibility() {
        if isGameComplete {
            continueButtonLabel.isHidden = true
            homeButton?.isHidden = false
        } else {
            continueButtonLabel.isHidden = false
            homeButton?.isHidden = true
        }
    }
    
    // Refreshes the displayed results whenever the view becomes visible.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderResultsUI()
    }
    
    // Updates labels, colors, scores, and button appearance based on the duel outcome and game state.
    private func renderResultsUI() {
        if isGameComplete {
            if myRoundsWon > opponentRoundsWon {
                resultTitle.text = "VICTORY!"
                resultTitle.textColor = UIColor.spotifyGreenGlow
                player1Score.textColor = UIColor.spotifyGreen
                player1ScoreSmall.textColor = UIColor.spotifyGreen
                homeButton?.configuration?.background.backgroundColor = UIColor.spotifyGreenGlow
            } else if myRoundsWon < opponentRoundsWon {
                resultTitle.text = "DEFEAT"
                resultTitle.textColor = UIColor.systemRed
                player1Score.textColor = UIColor.systemRed
                player1ScoreSmall.textColor = UIColor.systemRed
                homeButton?.configuration?.background.backgroundColor = UIColor.systemRed
            } else {
                resultTitle.text = "TIE GAME"
                resultTitle.textColor = UIColor.systemOrange
                player1Score.textColor = UIColor.systemOrange
                player1ScoreSmall.textColor = UIColor.systemOrange
                homeButton?.configuration?.background.backgroundColor = UIColor.systemOrange
            }
        } else {
            resultTitle.text = "ROUND \(currentRound)"
            resultTitle.textColor = .white
            if didWin {
                player1Score.textColor = UIColor.spotifyGreen
                player1ScoreSmall.textColor = UIColor.spotifyGreen
                continueButtonLabel.configuration?.background.backgroundColor = UIColor.spotifyGreenGlow
            } else {
                player1Score.textColor = UIColor.systemRed
                player1ScoreSmall.textColor = UIColor.systemRed
                continueButtonLabel.configuration?.background.backgroundColor = UIColor.systemRed
            }
        }
        
        player1Score.text = String(player1ScoreValue)
        player1ScoreSmall.text = String(player1ScoreValue)
        player2ScoreSmall.text = String(player2ScoreValue)
    }
    
    // Starts listening for Firestore game updates to detect opponent readiness and round changes.
    private func startObserving(code: String) {
        listener = GameService.shared.observeGame(code: code) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let game):
                self.handleGameUpdate(game)
            case .failure(let error):
                print("Error observing game: \(error.localizedDescription)")
            }
        }
    }
    
    // Processes multiplayer game changes and handles transitions between rounds and final results.
    private func handleGameUpdate(_ game: Game) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let opponentUID = (game.hostId == myUID) ? game.guestId : game.hostId
        
        if let opponentUID, let readyDict = game.playerReadyForNext {
            opponentReady = readyDict[opponentUID] ?? false
        }
        
        updateContinueButton()
        
        switch game.status {
        case .playing:
            // Both players ready and new round started - transition back to game
            if !hasTransitioned {
                print("[DUEL RESULTS] Game status is .playing, transitioning back to GameViewController")
                print("hasTransitioned was: false, setting to true")
                hasTransitioned = true
                listener?.remove()
                listener = nil
                autoContinueTimer?.invalidate()
                performSegue(withIdentifier: "gameViewFromResult", sender: game)
            } else {
                print("[DUEL RESULTS] Game status is .playing but hasTransitioned is already true")
            }
        case .finished:
            guard !hasTransitioned, !isGameComplete else { break }
            hasTransitioned = true
            print("[DUEL RESULTS] Game is finished — showing final results")
            listener?.remove()
            listener = nil
            autoContinueTimer?.invalidate()
            
            isGameComplete = true
            myRoundsWon = game.playerRoundsWon?[myUID] ?? myRoundsWon
            if let opponentUID {
                opponentRoundsWon = game.playerRoundsWon?[opponentUID] ?? opponentRoundsWon
            }
            configureButtonVisibility()
            renderResultsUI()
            break
        default:
            print("[DUEL RESULTS] Game status: \(game.status.rawValue)")
            break
        }
    }
    
    // Updates the continue button title based on the current round and whether the opponent is ready.
    private func updateContinueButton() {
        guard !isGameComplete else { return }
        
        // Check if this is the last round
        let isLastRound = (currentRound >= totalRounds)
        
        if isLastRound {
            // On the last round, show "End Game"
            if opponentReady {
                continueButtonLabel.setTitle("End Game (Opponent Ready)", for: .normal)
            } else {
                continueButtonLabel.setTitle("End Game", for: .normal)
            }
        } else {
            // Not the last round, show next round number
            if opponentReady {
                continueButtonLabel.setTitle("Continue (Opponent Ready)", for: .normal)
            } else {
                continueButtonLabel.setTitle("Continue to Round \(currentRound + 1)", for: .normal)
            }
        }
    }
    
    // Starts a countdown timer that automatically continues if the player does not press the button.
    private func startAutoContinueTimer() {
        autoContinueTimer = Timer.scheduledTimer(withTimeInterval: autoContinueDelay, repeats: false) { [weak self] _ in
            self?.autoContinue()
        }
    }
    
    // Automatically triggers the continue action after the timer expires.
    private func autoContinue() {
        guard !isGameComplete, !hasMarkedReady else { return }
        continueButtonPressed(self)
    }
    
    // Marks the player as ready for the next round or ends the game after the final round.
    @IBAction func continueButtonPressed(_ sender: Any) {
        guard let gameCode else {
            dismiss(animated: true)
            return
        }
        
        guard !isGameComplete else { return }
        guard !hasMarkedReady else { return }
        
        hasMarkedReady = true
        continueButtonLabel.isEnabled = false
        autoContinueTimer?.invalidate()
        
        // Check if this is the last round
        let isLastRound = (currentRound >= totalRounds)
        
        if isLastRound {
            // Last round - end the game immediately without waiting for opponent
            print("[DUEL RESULTS] Last round - ending game immediately")
            Task {
                do {
                    try await GameService.shared.endGame(code: gameCode)
                    // The listener will handle the transition when status becomes .finished
                } catch {
                    print("Error ending game: \(error.localizedDescription)")
                    await MainActor.run {
                        self.continueButtonLabel.isEnabled = true
                        self.hasMarkedReady = false
                    }
                }
            }
        } else {
            // Not the last round - wait for both players to be ready
            Task {
                do {
                    print("[DUEL RESULTS] Marking player as ready")
                    try await GameService.shared.markReady(code: gameCode, playlist: songs)
                    // If we were the second player ready, the transaction already advanced
                    // the round or finished the game. Both listeners react to the status change.
                } catch {
                    print("Error marking ready: \(error.localizedDescription)")
                    await MainActor.run {
                        self.continueButtonLabel.isEnabled = true
                        self.hasMarkedReady = false
                    }
                }
            }
        }
    }
    
    // Have it return home
    @IBAction func homeButtonPressed(_ sender: Any) {
        guard isGameComplete else { return }
        
        print("[DUEL RESULTS] Home button pressed - unwind segue will handle navigation")
        
        // The unwind segue connected in the storyboard will automatically
        // dismiss all the modal view controllers and return to HomeViewController.
        // No code needed here - the segue handles everything!
        
    }
    
    // Passes multiplayer game information and round history to the next game screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gameViewFromResult" {
            if let gameVC = segue.destination as? GameViewController {
                gameVC.gameCode = gameCode
                // The destination is a fresh instance — its own viewDidLoad
                // resets currentAttempts / prevGuesses / didWin, so we only
                // hand over identity and cross-round data.
                gameVC.matchResultHistory = matchResultList
                
                print("[DUEL RESULTS] Passing match history to GameViewController:")
                print("   Total rounds in history: \(matchResultList.count)")
                for (index, entry) in matchResultList.enumerated() {
                    print("   Round \(index + 1): \(entry.song.name) by \(entry.song.artist)")
                }
            }
        }
    }
    
    // Returns the number of completed rounds displayed in the match history table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchResultList.count
    }
    
    // Configures each match history table cell with round information, artwork, and score results.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as! DuelResultsCustomTableViewCell
        
        let reversedIndex = matchResultList.count - 1 - indexPath.row
        let entry = matchResultList[reversedIndex]
        let song = entry.song
        
        cell.trackNumber.text = "ROUND \(reversedIndex + 1)"
        
        cell.songName.text = song.name
        
        if let artworkData = song.albumArtData {
            cell.songImage.image = UIImage(data: artworkData)
        } else if let artworkURL = song.albumArt {
            loadImage(from: artworkURL, into: cell.songImage)
        } else {
            cell.songImage.image = UIImage(systemName: "music.note")
        }
        
        cell.songImage.layer.cornerRadius = 8
        cell.songImage.clipsToBounds = true
        
        cell.myScore.text = "\(entry.myScore)"
        cell.oppScore.text = "\(entry.opponentScore)"
        
        if entry.myScore > entry.opponentScore {
            cell.myScore.textColor = UIColor.spotifyGreen
        } else if entry.myScore == entry.opponentScore {
            cell.myScore.textColor = UIColor.white
        } else {
            cell.myScore.textColor = UIColor.systemRed
        }
        
        cell.oppScore.textColor = UIColor.white
        
        // Highlight the most recent round (current song)
        let isCurrentRound = (reversedIndex == matchResultList.count - 1) && (song == correctSong)
        if isCurrentRound {
            cell.backgroundColor = UIColor.spotifyGreen.withAlphaComponent(0.1)
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    // Downloads album artwork from a URL and updates the provided image view asynchronously.
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}
