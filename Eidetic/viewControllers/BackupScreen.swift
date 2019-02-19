//
//  BackupScreen.swift
//  Eidetic
//
//  Created by user147964 on 2/19/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class BackupScreen: UIViewController {
    
    @IBOutlet weak var saveDataToiCloudLabel: UILabel!
    
    @IBOutlet weak var retrieveDataFromiCloudLabel: UILabel!
    
    let database = CKContainer.default().privateCloudDatabase
    
    override func viewDidLoad() {
        print("View loaded")
        
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(BackupScreen.saveDataToiCloud))
        saveDataToiCloudLabel.isUserInteractionEnabled = true
        saveDataToiCloudLabel.addGestureRecognizer(saveTap)
        
        let retrieveTap = UITapGestureRecognizer(target: self, action: #selector(BackupScreen.saveDataToiCloud))
        retrieveDataFromiCloudLabel.isUserInteractionEnabled = true
        retrieveDataFromiCloudLabel.addGestureRecognizer(retrieveTap)
    }
    
    @objc func saveDataToiCloud(){
        do{
            let allTagsData = try String(contentsOf: FileManager.tagsFileURL, encoding: .utf8)
            let allDirectoriesData = try String(contentsOf: FileManager.directoriesURL, encoding: .utf8)
        
            let newTagsRecord = CKRecord(recordType: "TagsDataString", recordID: CKRecord.ID(recordName: "TagsDataString"))
            newTagsRecord.setValue(allTagsData, forKey: "Tags")
            
            let newDirectoriesRecord = CKRecord(recordType: "DirectoriesDataString", recordID: CKRecord.ID(recordName: "DirectoriesDataString"))
            newDirectoriesRecord.setValue(allDirectoriesData, forKey: "Directories")
            
            database.save(newTagsRecord) { (record, error) in
                print(error, "error")
                guard record != nil else {return}
                print("record saved!")
            }
            
            database.save(newDirectoriesRecord) { (record, error) in
                print(error, "error")
                guard record != nil else {return}
                print("record saved!")
            }
            
        }catch{
            print("Couldn't fetch data to save")
        }
    }
    
    @objc func retrieveDataFromiCloud(){
        
    }
}
