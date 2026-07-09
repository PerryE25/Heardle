//
//  SearchView.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/9/26.
//

import UIKit

protocol SearchViewDelegate: AnyObject {
    func searchViewDidTapSearch(_ searchView: SearchView)
}

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
