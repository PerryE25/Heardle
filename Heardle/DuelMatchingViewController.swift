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

class DuelMatchingViewController: UIViewController {
    

    @IBOutlet weak var playerOneView: UIStackView!
    @IBOutlet weak var playerTwoView: UIStackView!
    @IBOutlet weak var matchSettingsView: UIStackView!
    @IBOutlet weak var waitingForPlayerView: UIStackView!
    
    @IBOutlet weak var inviteCodeLabel: UIStackView!
    @IBOutlet weak var shareLinkButtonLabel: UIButton!
    @IBOutlet weak var inviteCodeCopyLabel: UIButton!
    @IBOutlet weak var inviteFriendView: UIStackView!
    @IBOutlet weak var playlistButtonLabel: UIButton!
    @IBOutlet weak var roundsButtonLabel: UIButton!
    @IBOutlet weak var guessTimerButtonLabel: UIButton!
    @IBOutlet weak var explicitButtonLabel: UIButton!
    
    
    let playlistOptions = [("Today's Favorites", UIColor.white), ("Top 50", UIColor.white), ("Top 100", UIColor.white), ("Top 200", UIColor.white), ("Top 500", UIColor.white), ("Top 1000", UIColor.white)]
    let songRoundOptions = [("1 Round", UIColor.white), ("2 Rounds", UIColor.white), ("3 Rounds", UIColor.white), ("4 Rounds", UIColor.white), ("5 Rounds", UIColor.white)]
    let guessTimerOptions = [("On", UIColor.spotifyGreen), ("Off", UIColor.systemRed)]
    let explicitSongOptions = [("Allowed", UIColor.spotifyGreen), ("Restricted", UIColor.systemRed)]
    var settingOptions: [String: [(String, UIColor)]] = [:]
    var settingOptionsAnswers: [String: String]  = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingOptions = [
            "Playlist": playlistOptions, "Song Round": songRoundOptions, "Guess Timer": guessTimerOptions, "Explicit": explicitSongOptions]
        for (key, _) in settingOptions {
            settingOptionsAnswers[key] = ""
        }
        
        
    }
    
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
        settingOptionAdd(button: guessTimerButtonLabel, options: guessTimerOptions, key: "Guess Timer")
        settingOptionAdd(button: explicitButtonLabel, options: explicitSongOptions, key: "Explicit")
    }
    
    func settingOptionAdd(button: UIButton, options: [(String, UIColor)], key: String) {
        var result: [UIAction] = []
        for option in options {
            let element = UIAction(title: option.0) {
                _ in
                self.settingOptionsAnswers[key] = option.0
                button.configuration?.title = self.settingOptionsAnswers[key]
                button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                    var result = attributes
                    result.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
                    result.foregroundColor = option.1
                    return result
                }
                print(self.settingOptionsAnswers)
            }
            result.append(element)
        }
        

        button.menu = UIMenu(title: key, children: result)
        button.showsMenuAsPrimaryAction = true
    }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
