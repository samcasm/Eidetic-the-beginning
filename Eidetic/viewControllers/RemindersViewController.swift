//
//  RemindersViewController.swift
//  Eidetic
//
//  Created by user147964 on 2/22/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Photos

class RemindersViewController: UITableViewController, ReminderCellDelegate {
    func deleteReminder(cell: ReminderCell) {
        let indexPath = tableView.indexPath(for: cell)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [cell.reminderID])
        self.imageIDs.remove(at: (indexPath?.item)!)
        self.reminderPHAssets = PHAsset.fetchAssets(withLocalIdentifiers: self.imageIDs, options: nil)
        tableView.reloadData()
    }
    
    
    var scheduledReminders: [UNNotificationRequest] = []
    var reminderPHAssets: PHFetchResult<PHAsset>!
    var imageIDs: [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notifications) in
        
            print(notifications)
            self.scheduledReminders = notifications
            
        }
        
    }
    
    override func viewDidLoad() {
        print("viewDidLoad")
        self.title = "Reminders"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.imageIDs =  scheduledReminders.map { $0.identifier }
        self.reminderPHAssets = PHAsset.fetchAssets(withLocalIdentifiers: self.imageIDs, options: nil)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard reminderPHAssets != nil else {return 0}
        return reminderPHAssets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let asset = reminderPHAssets.object(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath) as! ReminderCell
        cell.delegate = self
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil) { (image, _) in
            
            cell.thumbnailImage.image = image
            cell.reminderLabel.text = "Reminder"
            cell.reminderID = asset.localIdentifier
        }
        return cell
    }
}
