//
//  ViewController.swift
//  Eidetic
//
//  Created by user145467 on 11/30/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recentSearches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.recentSearchesTableView.dequeueReusableCell(withIdentifier: "RecentSearchCell") as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = self.recentSearches[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.text = self.recentSearches[indexPath.row]
        print("You tapped cell number \(indexPath.row).")
    }
    
    
    func clearSelections(allowsMultipleSelection: Bool)  {
        collectionView.allowsMultipleSelection = allowsMultipleSelection
        let selectedCells: NSArray = _selectedCells
        for cellPath in selectedCells {
            guard let selectedCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCell.self), for: cellPath as! IndexPath) as? PhotoCell
                else { fatalError("unexpected cell in collection view") }
            selectedCell.isSelected = false
        }
        _selectedCells.removeAllObjects()
        
        if allowsMultipleSelection {
            selectButton.title = "Cancel"
            navigationController?.isToolbarHidden = false
            self.navigationItem.title = "Select Items"
            searchBar.isUserInteractionEnabled = false
            searchBar.alpha = 0.75
            searchBar.searchBarStyle = .minimal
            searchBar.isTranslucent = false
            addTagButton.isEnabled = _selectedCells.count > 0 ? true : false
        }else{
            selectButton.title = "Select"
            navigationController?.isToolbarHidden = true
            self.navigationItem.title = ""
            searchBar.isUserInteractionEnabled = true
            searchBar.alpha = 1
            searchBar.searchBarStyle = .default
            searchBar.isTranslucent = true
            
        }
        collectionView.reloadData()
    }
}
