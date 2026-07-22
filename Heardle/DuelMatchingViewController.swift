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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        matchSettingsView.layer.borderWidth = 1
        matchSettingsView.layer.borderColor = UIColor.spotifyLightGrey.cgColor
        playerOneView.layer.borderWidth = 2
        playerOneView.layer.borderColor = UIColor.spotifyGreenGlow.cgColor
        
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = UIColor.spotifyLightGrey.cgColor
        dashedBorder.fillColor = nil
        dashedBorder.lineWidth = 2
        dashedBorder.lineDashPattern = [6, 3]
        dashedBorder.frame = playerTwoView.bounds
        dashedBorder.path = UIBezierPath(roundedRect: playerTwoView.bounds, cornerRadius: 10).cgPath
        playerTwoView.layer.addSublayer(dashedBorder)
        // Do any additional setup after loading the view.
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
