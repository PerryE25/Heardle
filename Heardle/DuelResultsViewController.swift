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

class DuelResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var player1Score: UILabel!
    @IBOutlet weak var player1ScoreSmall: UILabel!
    @IBOutlet weak var player2ScoreSmall: UILabel!
    @IBOutlet weak var continueButtonLabel: UIButton!
    
    var matchResultList: [Song] = songs
    var player1ScoreValue = 13
    var player2ScoreValue = 10
    
    let textCellIdentifier = "TextCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(matchResultList.count)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchResultList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath) as! DuelResultsCustomTableViewCell
                
        return cell
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
