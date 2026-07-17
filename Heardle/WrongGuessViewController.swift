//
//  WrongGuessViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class WrongGuessViewController: UIViewController {

    
    @IBOutlet weak var topText: UILabel!
    @IBOutlet weak var miniView: UIView!
    override func viewDidLoad() {
        miniView.layer.cornerRadius = 30
        topText.font = UIFont.boldSystemFont(ofSize: 40.0)
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func returnToGame(_ sender: Any) {
        self.dismiss(animated: true)
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
