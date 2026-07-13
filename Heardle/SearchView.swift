//
//  SearchView.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/9/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// A delegate protocol for responding to taps on the search view.
protocol SearchViewDelegate: AnyObject {
    
    // Called when the user taps the search view.
    func searchViewDidTapSearch(_ searchView: SearchView)
}

// A custom view that detects taps and notifies its delegate to present the full-screen search interface.
class SearchView: UIView {

    weak var delegate: SearchViewDelegate?
    
    // Adds a tap gesture recognizer after the view is loaded from the storyboard.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSearch))
        addGestureRecognizer(tap)
    }

    // Notifies the delegate when the search view is tapped.
    @objc private func didTapSearch() {
        delegate?.searchViewDidTapSearch(self)
    }
}
