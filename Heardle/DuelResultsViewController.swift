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

// Displays duel results, scores, and a breakdown list for both players.
class DuelResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var player1Score: UILabel!
    @IBOutlet weak var player1ScoreSmall: UILabel!
    @IBOutlet weak var player2ScoreSmall: UILabel!
    @IBOutlet weak var continueButtonLabel: UIButton!
    
    @IBOutlet weak var matchBreakdownView: UIStackView!
    
    @IBOutlet weak var resultScoreView: UIStackView!
    
    var matchResultList: [Song] = songs
    var player1ScoreValue = 13
    var player2ScoreValue = 10
    
    let textCellIdentifier = "TextCell"
    
    // Initializes table view delegates and styles the results UI.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        matchBreakdownView.layer.borderWidth = 1
        matchBreakdownView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        resultScoreView.layer.borderWidth = 1
        resultScoreView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        // Do any additional setup after loading the view.
    }
    
    // Updates the title, colors, and score labels each time the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if didWin {
            resultTitle.text = "VICTORY"
            resultTitle.textColor = UIColor.spotifyGreenGlow
            player1Score.textColor = UIColor.spotifyGreen
            player1ScoreSmall.textColor = UIColor.spotifyGreen
            continueButtonLabel.configuration?.background.backgroundColor = UIColor.spotifyGreenGlow
        } else {
            resultTitle.text = "LOSS"
            resultTitle.textColor = UIColor.systemRed
            player1Score.textColor = UIColor.systemRed
            player1ScoreSmall.textColor = UIColor.systemRed
            continueButtonLabel.configuration?.background.backgroundColor = UIColor.systemRed
        }
        
        player1Score.text = String(player1ScoreValue)
        player1ScoreSmall.text = String(player1ScoreValue)
        player2ScoreSmall.text = String(player2ScoreValue)
        
    }
    
    // Returns the number of rows for the match breakdown list.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchResultList.count
    }
    
    // Dequeues and configures a results cell for the given row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as! DuelResultsCustomTableViewCell
                
        return cell
    }
    


}

