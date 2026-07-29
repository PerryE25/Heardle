//
//  DuelMatchingViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

var songList: [Song] = []
var clipDurations = [1, 2, 4, 7, 11, 16]
var playerStatus = ["host": 0, "guest": 0]

// Sample playlists for testing multiplayer
// These playlists are populated from the global 'songs' array (loaded from Spotify/Firebase)
var samplePlaylists: [String: [Song]] = [:]

// Creates predefined multiplayer playlists from the loaded songs collection,
// filtering out songs that cannot be played in multiplayer mode.
func setupSamplePlaylists() {
    guard !songs.isEmpty else {
        print("[PLAYLISTS] Cannot setup playlists - songs array is empty")
        return
    }
    
    // Filter to only include songs with BOTH trackId AND previewURL (required for multiplayer)
    let playableSongs = songs.filter {
        $0.trackId != nil && $0.previewURL != nil
    }
    
    guard !playableSongs.isEmpty else {
        print("[PLAYLISTS] Cannot setup playlists - no playable songs found")
        print("[PLAYLISTS] Songs need both trackId and previewURL to be playable in multiplayer")
        return
    }
    
    print("[PLAYLISTS] Setting up playlists from \(playableSongs.count) playable songs")
    
    // Today's Favorites - First 10 songs (or all if less than 10)
    let favoritesCount = min(10, playableSongs.count)
    samplePlaylists["Today's Favorites"] = Array(playableSongs.prefix(favoritesCount))
    
    // Top 50 - First 50 songs (or all if less)
    let top50Count = min(50, playableSongs.count)
    samplePlaylists["Top 50"] = Array(playableSongs.prefix(top50Count))
    
    // Top 100 - First 100 songs (or all if less)
    let top100Count = min(100, playableSongs.count)
    samplePlaylists["Top 100"] = Array(playableSongs.prefix(top100Count))
    
    // Top 200 - First 200 songs (or all if less)
    let top200Count = min(200, playableSongs.count)
    samplePlaylists["Top 200"] = Array(playableSongs.prefix(top200Count))
    
    // Top 500 - First 500 songs (or all if less)
    let top500Count = min(500, playableSongs.count)
    samplePlaylists["Top 500"] = Array(playableSongs.prefix(top500Count))
    
    // Top 1000 - All songs
    samplePlaylists["Top 1000"] = playableSongs
    
    print("[PLAYLISTS] Created playlists:")
    print("   - Today's Favorites: \(samplePlaylists["Today's Favorites"]?.count ?? 0) songs")
    print("   - Top 50: \(samplePlaylists["Top 50"]?.count ?? 0) songs")
    print("   - Top 100: \(samplePlaylists["Top 100"]?.count ?? 0) songs")
    print("   - Top 200: \(samplePlaylists["Top 200"]?.count ?? 0) songs")
    print("   - Top 500: \(samplePlaylists["Top 500"]?.count ?? 0) songs")
    print("   - Top 1000: \(samplePlaylists["Top 1000"]?.count ?? 0) songs")
}

// Configures the multiplayer lobby, handles player matching,
// and manages duel settings before the game begins.
class DuelMatchingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var playerOneView: UIStackView!
    @IBOutlet weak var playerTwoView: UIStackView!
    @IBOutlet weak var matchSettingsView: UIStackView!
    @IBOutlet weak var waitingForPlayerView: UIStackView!
    
    @IBOutlet weak var inviteCodeLabel: UIStackView!
    @IBOutlet weak var shareLinkButtonLabel: UIButton!
    @IBOutlet weak var playlistButtonLabel: UIButton!
    @IBOutlet weak var roundsButtonLabel: UIButton!
    @IBOutlet weak var inviteFriendView: UIStackView!
    @IBOutlet weak var inviteTextLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var inviteJoinTextField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var segmentedControlOutlet: UISegmentedControl!
    @IBOutlet weak var joinFriendView: UIStackView!
    
    // Stores the available playlist, round, and explicit-content options used in the lobby settings menu.
    let playlistOptions = [("Today's Favorites", UIColor.white), ("Top 50", UIColor.white), ("Top 100", UIColor.white), ("Top 200", UIColor.white), ("Top 500", UIColor.white), ("Top 1000", UIColor.white)]
    let songRoundOptions = [("1 Round", UIColor.white), ("2 Rounds", UIColor.white), ("3 Rounds", UIColor.white), ("4 Rounds", UIColor.white), ("5 Rounds", UIColor.white)]
    let explicitSongOptions = [("Allowed", UIColor.spotifyGreen), ("Restricted", UIColor.systemRed)]
    // Stores the currently selected lobby settings and their values.
    var settingOptions: [String: [(String, UIColor)]] = [:]
    var settingOptionsAnswers: [String: String]  = [:]
    var gameCode: String!
    var hasTransitioned = false
    // Tracks whether the current player is creating a lobby or joining an existing lobby.
    var isCreating = true
    
    private var listener: ListenerRegistration?
    private var hasAnimatedPlayerTwo = false
    private var isObserving = false
    
    // Initializes the multiplayer lobby, loads playlists, configures UI controls,
    // and creates or joins a Firebase game session.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("[MULTIPLAYER] ViewDidLoad - isCreating: \(isCreating)")
        
        // Setup playlists from loaded songs
        if samplePlaylists.isEmpty {
            setupSamplePlaylists()
        }
        
        // Start with default playlist
        songList = samplePlaylists["Today's Favorites"] ?? []
        print("[SONGS] Loaded \(songList.count) songs from default playlist")
        
        if songList.isEmpty {
            print("[SONGS] WARNING: No playable songs available!")
            print("   This could mean:")
            print("   - Songs haven't loaded from Spotify/Firebase yet")
            print("   - No songs have preview URLs")
            showAlert(title: "No Playable Songs",
                      message: "Please wait for songs to load from your library, or make sure you have songs with preview URLs.")
        }
        
        inviteJoinTextField?.delegate = self
        inviteJoinTextField?.autocapitalizationType = .allCharacters
        inviteJoinTextField?.autocorrectionType = .no
        
        setupSegmentedControl()
        
        if isCreating {
            print("[MULTIPLAYER] Setting initial mode to INVITE")
            segmentedControlOutlet.selectedSegmentIndex = 0  // "Invite"
            showInviteMode()
        } else {
            print("[MULTIPLAYER] Setting initial mode to JOIN")
            segmentedControlOutlet.selectedSegmentIndex = 1  // "Join"
            showJoinMode()
        }
        
        settingOptions = [
            "Playlist": playlistOptions, "Song Round": songRoundOptions, "Explicit": explicitSongOptions]
        for (key, _) in settingOptions {
            settingOptionsAnswers[key] = ""
        }
        
        if isCreating {
            gameCode = GameService.shared.generateCode()
            print("[HOST] Generated game code: \(gameCode ?? "nil")")
            inviteTextLabel.text = gameCode
            
            // Set default rounds to 1 Round
            settingOptionsAnswers["Song Round"] = "1 Round"
            roundsButtonLabel.configuration?.title = "1 Round"
            
            Task {
                do {
                    print("[HOST] Creating game in Firebase...")
                    try await GameService.shared.createGame(code: gameCode)
                    print("[HOST] Game created successfully!")
                    
                    // Push default settings to Firebase
                    print("[HOST] Setting default to 1 Round")
                    try await GameService.shared.updateSettings(code: gameCode, settings: ["totalRounds": 1])
                    
                    startObserving()
                } catch {
                    print("[HOST] Failed to create game: \(error)")
                }
            }
        }
        else {
            inviteTextLabel.text = gameCode
            startObserving()
        }
    }
    
    // Configures the appearance and text styling of the invite/join segmented control.
    private func setupSegmentedControl() {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        
        segmentedControlOutlet.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControlOutlet.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        print("[SEGMENT] Configured - Normal: white text, Selected: black text")
    }
    
    // Starts listening for Firebase game updates to synchronize lobby state between players.
    private func startObserving() {
        guard !isObserving else {
            print("[MULTIPLAYER] Already observing game \(gameCode ?? "unknown") - skipping")
            return
        }
        
        print("[MULTIPLAYER] Starting to observe game: \(gameCode ?? "nil")")
        isObserving = true
        listener = GameService.shared.observeGame(code: gameCode) {
            [weak self] result in
            switch result {
            case .success(let game):
                print("[MULTIPLAYER] Received game update - Status: \(game.status.rawValue), Host: \(game.hostId), Guest: \(game.guestId ?? "none")")
                self?.render(game)
            case .failure(let error):
                print("[MULTIPLAYER] Error observing game: \(error.localizedDescription)")
            }
        }
    }
    
    // Removes Firebase listeners and releases resources when the lobby controller is destroyed.
    deinit {
        print("[MULTIPLAYER] DuelMatchingViewController deallocating")
        listener?.remove()
        isObserving = false
    }
    
    // Applies lobby styling, borders, and menu configurations when the view appears.
    override func viewDidAppear(_ animated: Bool) {
        matchSettingsView.layer.borderWidth = 1
        matchSettingsView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        playerOneView.layer.borderWidth = 2
        playerOneView.layer.borderColor = UIColor.spotifyGreenGlow.cgColor
        playerTwoView.layer.borderWidth = 2
        playerTwoView.layer.borderColor = UIColor.spotifyGreenGlow.cgColor
        inviteCodeLabel.layer.borderWidth = 2
        inviteCodeLabel.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        shareLinkButtonLabel.layer.borderWidth = 1
        shareLinkButtonLabel.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        inviteFriendView.layer.borderWidth = 1
        inviteFriendView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = UIColor.spotifyLightGrey.cgColor
        dashedBorder.fillColor = nil
        dashedBorder.lineWidth = 2
        dashedBorder.lineDashPattern = [6, 3]
        dashedBorder.frame = waitingForPlayerView.bounds
        dashedBorder.path = UIBezierPath(roundedRect: waitingForPlayerView.bounds, cornerRadius: 10).cgPath
        waitingForPlayerView.layer.addSublayer(dashedBorder)
        settingOptionAdd(button: playlistButtonLabel, options: playlistOptions, key: "Playlist")
        settingOptionAdd(button: roundsButtonLabel, options: songRoundOptions, key: "Song Round")
    }
    
    // Copies the current game invite code to the device clipboard.
    @IBAction func copyButtonPressed(_ sender: Any) {
        UIPasteboard.general.string = inviteTextLabel.text
    }
    
    // Opens the share sheet allowing players to send the invite code to another user.
    @IBAction func shareButtonPressed(_ sender: Any) {
        let vc = UIActivityViewController(activityItems: ["""
            Think you can beat me at Heardle? Join my 1v1 with code: \(String(describing: inviteTextLabel.text))
            """], applicationActivities: nil)
        
        present(vc, animated: true)
    }
    
    // Opens the share sheet allowing players to send the invite code to another user.
    func render(_ game: Game) {
        guard let myUID = Auth.auth().currentUser?.uid else {
            print("[MULTIPLAYER] Cannot render - no user UID")
            return
        }
        let isHost = (game.hostId == myUID)
        let guestJoined = (game.guestId != nil)
        
        print("[RENDER] Status: \(game.status.rawValue) | I am: \(isHost ? "HOST" : "GUEST") | Guest joined: \(guestJoined)")
        
        switch game.status {
        case .waiting:
            print("[WAITING] In lobby - Guest: \(guestJoined ? "YES" : "NO")")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if guestJoined && !self.hasAnimatedPlayerTwo {
                    print("[ANIMATION] Player 2 joining - starting animation")
                    self.hasAnimatedPlayerTwo = true
                    self.animatePlayerTwoJoining()
                } else if !guestJoined && isHost {
                    print("[HOST] Waiting for guest to join")
                    self.waitingForPlayerView.isHidden = false
                    self.playerTwoView.isHidden = true
                } else if guestJoined && !self.hasAnimatedPlayerTwo {
                    print("[GUEST] Joined full lobby - skipping animation")
                    self.waitingForPlayerView.isHidden = true
                    self.playerTwoView.isHidden = false
                    self.hasAnimatedPlayerTwo = true
                }
                
                if guestJoined {
                    self.inviteFriendView.isHidden = true
                    self.joinFriendView.isHidden = true
                    self.segmentedControlOutlet.isHidden = true
                    print("[UI] Hiding segmented control and invite/join views - both players in lobby")
                } else {
                    if self.isCreating {
                        self.inviteFriendView.isHidden = false
                        self.joinFriendView.isHidden = true
                    } else {
                        self.inviteFriendView.isHidden = true
                        self.joinFriendView.isHidden = false
                    }
                    self.segmentedControlOutlet.isHidden = false
                    print("[UI] Showing segmented control and \(self.isCreating ? "invite" : "join") view")
                }
                
                self.setSettingsEnabled(isHost)
                print("[SETTINGS] Settings \(isHost ? "ENABLED" : "DISABLED") for \(isHost ? "host" : "guest")")
                
                self.continueButton.isHidden = !isHost
                self.continueButton.isEnabled = isHost && guestJoined
                
                if isHost && guestJoined {
                    print("[HOST] Continue button enabled - both players ready")
                }
                
                if !isHost {
                    print("[GUEST] Applying host's settings")
                    self.applyRemoteSettings(game)
                }
            }
            
        case .playing:
            guard !hasTransitioned else {
                print("[PLAYING] Already transitioned - ignoring")
                return
            }
            print("[PLAYING] Starting game! Transitioning to GameViewController...")
            hasTransitioned = true
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("[TRANSITION] Performing segue to game with code: \(self.gameCode ?? "nil")")
                
                self.listener?.remove()
                self.listener = nil
                self.isObserving = false
                
                self.performSegue(withIdentifier: "showGame", sender: self.gameCode)
            }
            
        case .roundResults:
            print("[ROUND_RESULTS] Round finished")
            
        case .finished:
            print("[FINISHED] Game over")
            break
        }
        
    }
    
    // Applies host-selected game settings to the guest player's lobby interface.
    private func applyRemoteSettings(_ game: Game) {
        print("[GUEST_SETTINGS] Applying remote settings from host")
        
        if let playlist = game.playlistName {
            print("   - Playlist: \(playlist)")
            playlistButtonLabel.configuration?.title = playlist
            
            // Guest also needs to update their local songList
            if let newPlaylist = samplePlaylists[playlist] {
                songList = newPlaylist
                print("[GUEST_SETTINGS] Loaded playlist '\(playlist)' with \(songList.count) songs")
            }
        }
        
        if let rounds = game.totalRounds {
            print("   - Rounds: \(rounds)")
            roundsButtonLabel.configuration?.title = "\(rounds) Round\(rounds == 1 ? "" : "s")"
        }
    }
    
    // Applies host-selected game settings to the guest player's lobby interface.
    private func animatePlayerTwoJoining() {
        print("[ANIMATION] Animating player 2 joining the lobby")
        
        playerTwoView.isHidden = false
        playerTwoView.alpha = 0
        playerTwoView.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.waitingForPlayerView.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            self.waitingForPlayerView.alpha = 0
            
            self.playerTwoView.transform = .identity
            self.playerTwoView.alpha = 1
        } completion: { _ in
            print("[ANIMATION] Player 2 join animation complete")
            self.waitingForPlayerView.isHidden = true
            self.waitingForPlayerView.transform = .identity
            self.waitingForPlayerView.alpha = 1
        }
    }
    
    // Animates the second player's appearance when they join the lobby.
    func settingOptionAdd(button: UIButton, options: [(String, UIColor)], key: String) {
        var actions: [UIAction] = []
        for option in options {
            let element = UIAction(title: option.0) { [weak self] _ in
                guard let self else { return }
                self.settingOptionsAnswers[key] = option.0
                button.configuration?.title = option.0
                button.configuration?.titleTextAttributesTransformer =
                UIConfigurationTextAttributesTransformer { attributes in
                    var result = attributes
                    result.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
                    result.foregroundColor = option.1
                    return result
                }
                self.pushSetting(key: key, value: option.0)
            }
            actions.append(element)
        }
        button.menu = UIMenu(title: key, children: actions)
        button.showsMenuAsPrimaryAction = true
    }
    
    // Creates a dropdown menu for a lobby setting button and handles selection changes.
    private func pushSetting(key: String, value: String) {
        guard isCreating else {
            print("[SETTINGS] Guest attempted to change settings - blocked")
            return
        }
        
        var update: [String: Any] = [:]
        switch key {
        case "Playlist":
            update["playlistName"] = value
            // Update the local songList when playlist changes
            if let newPlaylist = samplePlaylists[value] {
                songList = newPlaylist
                print("[HOST_SETTINGS] Switched to playlist '\(value)' with \(songList.count) songs")
            } else {
                print("[HOST_SETTINGS] WARNING: Playlist '\(value)' not found, keeping current playlist")
            }
        case "Song Round":
            update["totalRounds"] = Int(value.prefix(1)) ?? 1
        default:
            return
        }
        
        print("[HOST_SETTINGS] Updating \(key) to '\(value)'")
        Task {
            do {
                try await GameService.shared.updateSettings(code: gameCode, settings: update)
                print("[HOST_SETTINGS] Successfully updated \(key)")
            } catch {
                print("[HOST_SETTINGS] Failed to update \(key): \(error)")
            }
        }
    }
    
    // Sends updated host-selected settings to Firebase and updates local playlist data.
    private func setSettingsEnabled(_ enabled: Bool) {
        playlistButtonLabel.isEnabled = enabled
        roundsButtonLabel.isEnabled = enabled
    }
    
    // Enables or disables lobby setting controls depending on the player's role.
    @IBAction func continueButtonPressed(_ sender: Any) {
        print("[HOST] Continue button pressed - starting game!")
        print("   - Current gameCode: \(gameCode ?? "nil")")
        print("   - Playlist size: \(songList.count)")
        print("[IMPORTANT] Make sure continueButton does NOT have a storyboard segue!")
        print("   The transition should happen via Firebase listener, not storyboard segue")
        
        continueButton.isEnabled = false
        
        Task {
            do {
                print("[HOST] Starting game with \(songList.count) songs in playlist")
                try await GameService.shared.startGame(code: gameCode, playlist: songList)
                print("[HOST] Game started successfully! Game status should now be 'playing'")
                print("   - Both host and guest should receive the update via Firebase listener")
                print("   - Waiting for render() to receive .playing status and trigger segue...")
            } catch {
                print("[HOST] Failed to start game: \(error.localizedDescription)")
                await MainActor.run {
                    self.continueButton.isEnabled = true
                }
            }
        }
    }
    
    // Starts the multiplayer game after the host confirms the lobby is ready.
    @IBAction func joinButtonPressed(_ sender: Any) {
        print("[GUEST] Join button PRESSED!")
        print("   - Button sender: \(sender)")
        print("   - Text field text: '\(inviteJoinTextField?.text ?? "nil")'")
        
        guard let code = inviteJoinTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              !code.isEmpty else {
            print("[GUEST] Invalid code entered")
            showAlert(title: "Invalid Code", message: "Please enter a valid game code.")
            return
        }
        
        print("[GUEST] Attempting to join game with code: \(code)")
        
        joinButton?.isEnabled = false
        inviteJoinTextField.isEnabled = false
        
        Task {
            do {
                print("[GUEST] Sending join request to Firebase...")
                let game = try await GameService.shared.joinGame(code: code)
                print("[GUEST] Successfully joined game!")
                print("   - Host ID: \(game.hostId)")
                print("   - Guest ID: \(game.guestId ?? "none")")
                print("   - Status: \(game.status.rawValue)")
                
                await MainActor.run {
                    print("[GUEST] Updating UI after successful join")
                    self.gameCode = code
                    self.isCreating = false
                    
                    self.joinFriendView?.isHidden = true
                    self.inviteFriendView?.isHidden = true
                    self.inviteTextLabel.text = code
                    self.playerTwoView.isHidden = false
                    self.waitingForPlayerView.isHidden = true
                    print("[GUEST] Set player views - I am Player 2")
                    
                    self.startObserving()
                    
                    self.render(game)
                }
                
            } catch {
                print("[GUEST] Failed to join game: \(error.localizedDescription)")
                await MainActor.run {
                    self.joinButton?.isEnabled = true
                    self.inviteJoinTextField.isEnabled = true
                    self.showAlert(title: "Join Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    // Allows a guest player to join an existing multiplayer game using an invite code.
    @IBAction func segmentControlAction(_ sender: UISegmentedControl) {
        print("[SEGMENT] Segment changed to index: \(sender.selectedSegmentIndex)")
        
        if sender.selectedSegmentIndex == 0 {
            print("[SEGMENT] Mode changed to: Invite")
            showInviteMode()
        } else {
            print("[SEGMENT] Mode changed to: Join")
            showJoinMode()
        }
    }
    
    // Switches between invite and join modes in the multiplayer lobby.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Displays an alert message to inform the user of errors or important events.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGame",
           let vc = segue.destination as? GameViewController,
           let code = sender as? String {
            print("[SEGUE] Preparing GameViewController with code: \(code)")
            vc.gameCode = code
        }
    }
    
    // Passes the multiplayer game code to the game screen during navigation.
    private func showInviteMode() {
        print("[MODE] Switching to INVITE mode")
        isCreating = true
        
        inviteFriendView?.isHidden = false
        joinFriendView?.isHidden = true
        
        print("[MODE] UI State - inviteFriendView: visible, joinFriendView: hidden")
        
        if gameCode == nil || gameCode.isEmpty {
            gameCode = GameService.shared.generateCode()
            print("[HOST] Generated new game code: \(gameCode ?? "nil")")
            inviteTextLabel.text = gameCode
            
            Task {
                do {
                    print("[HOST] Creating game in Firebase...")
                    try await GameService.shared.createGame(code: gameCode)
                    print("[HOST] Game created successfully!")
                    startObserving()
                } catch {
                    print("[HOST] Failed to create game: \(error.localizedDescription)")
                }
            }
        } else {
            print("[HOST] Reusing existing game code: \(gameCode ?? "nil")")
        }
    }
    
    // Configures the lobby for creating a new game and generates an invite code.
    private func showJoinMode() {
        print("[MODE] Switching to JOIN mode")
        isCreating = false
        
        if isObserving {
            print("[JOIN] Stopping observer for previous game")
            listener?.remove()
            listener = nil
            isObserving = false
        }
        
        hasAnimatedPlayerTwo = false
        hasTransitioned = false
        gameCode = nil
        print("[JOIN] Reset state - ready for new game")
        
        inviteFriendView?.isHidden = true
        joinFriendView?.isHidden = false
        
        print("[MODE] UI State - inviteFriendView: hidden, joinFriendView: visible")
        
        waitingForPlayerView.isHidden = true
        playerTwoView.isHidden = true
        
        inviteJoinTextField?.text = ""
        inviteJoinTextField?.isEnabled = true
        joinButton?.isEnabled = true
        
        if joinButton == nil {
            print("[JOIN] WARNING: joinButton is nil! Check storyboard connection.")
        } else {
            print("[JOIN] Join button is connected and enabled")
        }
    }
    
    // Restricts invite code input to valid uppercase letters and numbers while formatting input.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == inviteJoinTextField else { return true }
        
        if string.isEmpty { return true }
        
        let allowedCharacters = CharacterSet.uppercaseLetters.union(.decimalDigits)
        let characterSet = CharacterSet(charactersIn: string)
        
        if characterSet.isSubset(of: allowedCharacters.union(.lowercaseLetters)) {
            let currentText = (textField.text as NSString?) ?? ""
            let updatedText = currentText.replacingCharacters(in: range, with: string.uppercased())
            textField.text = updatedText
            return false
        }
        return characterSet.isSubset(of: allowedCharacters)
    }
}
