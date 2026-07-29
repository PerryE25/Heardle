//
//  DuelResultsCustomTableViewCell.swift
//  Heardle
//
//  Created by Sanchez, Victor J on 7/17/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// A custom row that shows player's results for one round
class DuelResultsCustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var trackNumber: UILabel!
    @IBOutlet weak var myScore: UILabel!
    @IBOutlet weak var oppScore: UILabel!
}
