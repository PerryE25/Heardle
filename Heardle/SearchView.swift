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

protocol SearchViewDelegate: AnyObject {
    func searchViewDidTapSearch(_ searchView: SearchView)
}

// A custom view where I can allow segues to full-screen search bar VCs
class SearchView: UIView {

    weak var delegate: SearchViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSearch))
        addGestureRecognizer(tap)
    }

    @objc private func didTapSearch() {
        delegate?.searchViewDidTapSearch(self)
    }
}
