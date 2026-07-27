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

// Displays duel results, scores, and a breakdown list for both players.
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
    
    var matchResultList: [Song] = []
    var player1ScoreValue: Int { myRoundsWon }
    var player2ScoreValue: Int { opponentRoundsWon }
    
    let textCellIdentifier = "TextCell"
    
    private var listener: ListenerRegistration?
    private var autoContinueTimer: Timer?
    private let autoContinueDelay: TimeInterval = 10.0
    private var opponentReady = false
    private var hasMarkedReady = false
    private var hasTransitioned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        matchBreakdownView.layer.borderWidth = 1
        matchBreakdownView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        resultScoreView.layer.borderWidth = 1
        resultScoreView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        
        matchResultList = prevGuesses
        
        configureButtonVisibility()
        
        if let gameCode {
            startObserving(code: gameCode)
        }
        
        updateContinueButton()
        
        if !isGameComplete {
            startAutoContinueTimer()
        }
    }
    
    deinit {
        listener?.remove()
        autoContinueTimer?.invalidate()
    }
    
    private func configureButtonVisibility() {
        if isGameComplete {
            continueButtonLabel.isHidden = true
            homeButton?.isHidden = false
        } else {
            continueButtonLabel.isHidden = false
            homeButton?.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            if didWin {
                resultTitle.text = "ROUND \(currentRound) WON!"
                resultTitle.textColor = UIColor.spotifyGreenGlow
                player1Score.textColor = UIColor.spotifyGreen
                player1ScoreSmall.textColor = UIColor.spotifyGreen
                continueButtonLabel.configuration?.background.backgroundColor = UIColor.spotifyGreenGlow
            } else {
                resultTitle.text = "ROUND \(currentRound) LOST"
                resultTitle.textColor = UIColor.systemRed
                player1Score.textColor = UIColor.systemRed
                player1ScoreSmall.textColor = UIColor.systemRed
                continueButtonLabel.configuration?.background.backgroundColor = UIColor.systemRed
            }
        }
        
        player1Score.text = String(player1ScoreValue)
        player1ScoreSmall.text = String(player1ScoreValue)
        player2ScoreSmall.text = String(player2ScoreValue)
    }
        
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
    
    private func handleGameUpdate(_ game: Game) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let opponentUID = (game.hostId == myUID) ? game.guestId : game.hostId
        
        if let opponentUID, let readyDict = game.playerReadyForNext {
            opponentReady = readyDict[opponentUID] ?? false
        }
        
        updateContinueButton()
        
        switch game.status {
        case .playing:
            if !hasTransitioned {
                hasTransitioned = true
                listener?.remove()
                listener = nil
                autoContinueTimer?.invalidate()
                dismiss(animated: true)
            }
        case .finished:
            break
        default:
            break
        }
    }
    
    private func updateContinueButton() {
        guard !isGameComplete else { return }
        
        if opponentReady {
            continueButtonLabel.setTitle("Continue (Opponent Ready)", for: .normal)
        } else {
            continueButtonLabel.setTitle("Continue to Round \(currentRound + 1)", for: .normal)
        }
    }
    
    
    private func startAutoContinueTimer() {
        autoContinueTimer = Timer.scheduledTimer(withTimeInterval: autoContinueDelay, repeats: false) { [weak self] _ in
            self?.autoContinue()
        }
    }
    
    private func autoContinue() {
        guard !isGameComplete, !hasMarkedReady else { return }
        continueButtonPressed(self)
    }
    
    
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
        
        Task {
            do {
                try await GameService.shared.markReady(code: gameCode)
                let game = try await GameService.shared.fetchGame(code: gameCode)
                
                guard let myUID = Auth.auth().currentUser?.uid else { return }
                let opponentUID = (game.hostId == myUID) ? game.guestId : game.hostId
                
                let myReady = game.playerReadyForNext?[myUID] ?? false
                let opReady = game.playerReadyForNext?[opponentUID ?? ""] ?? false
                let bothReady = myReady && opReady
                
                if bothReady {
                    if (game.currentRound ?? 0) >= (game.totalRounds ?? 1) {
                    } else {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        try? await GameService.shared.startNextRound(code: gameCode, playlist: songList)
                    }
                }
            } catch {
                print("Error marking ready: \(error.localizedDescription)")
                continueButtonLabel.isEnabled = true
                hasMarkedReady = false
            }
        }
    }
    
    @IBAction func homeButtonPressed(_ sender: Any) {
        guard isGameComplete else { return }
        dismiss(animated: true) {
            if let window = UIApplication.shared.windows.first,
               let rootVC = window.rootViewController {
                rootVC.dismiss(animated: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchResultList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as! DuelResultsCustomTableViewCell
        
        let reversedIndex = matchResultList.count - 1 - indexPath.row
        let song = matchResultList[reversedIndex]
        
        cell.trackNumber.text = "TRACK \(reversedIndex + 1)"
        
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
        
        cell.myScore.text = "\(myRoundsWon)"
        cell.oppScore.text = "\(opponentRoundsWon)"
        
        if myRoundsWon > opponentRoundsWon {
            cell.myScore.textColor = UIColor.spotifyGreen
        } else if myRoundsWon == opponentRoundsWon {
            cell.myScore.textColor = UIColor.white
        } else {
            cell.myScore.textColor = UIColor.systemRed
        }
        
        cell.oppScore.textColor = UIColor.white
        
        let isCorrectGuess = (song == correctSong)
        if isCorrectGuess {
            cell.backgroundColor = UIColor.spotifyGreen.withAlphaComponent(0.1)
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

