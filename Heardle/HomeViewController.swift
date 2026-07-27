//
//  HomeViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // Unwind segue action for returning to home from game results
    @IBAction func unwindToHome(_ unwindSegue: UIStoryboardSegue) {
        // This method allows other view controllers to unwind back to HomeViewController
        print("[HOME] Unwound back to home from \(type(of: unwindSegue.source))")
        // Any cleanup or refresh logic can go here
    }

}
