//
//  RulesViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// Shows the rules for the game
class RulesViewController: UIViewController {
    @IBOutlet weak var miniView: UIView!
    
    override func viewDidLoad() {
        miniView.layer.cornerRadius = 30
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func returnToPrevious(_ sender: Any) {
        self.dismiss(animated: true)
    }

}
