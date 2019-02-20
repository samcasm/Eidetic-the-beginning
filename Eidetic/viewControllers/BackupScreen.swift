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
        self.title = "iCloud Backup"
        
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(BackupScreen.saveDataToiCloud))
        saveDataToiCloudLabel.isUserInteractionEnabled = true
        saveDataToiCloudLabel.addGestureRecognizer(saveTap)
        
        let retrieveTap = UITapGestureRecognizer(target: self, action: #selector(BackupScreen.retrieveDataFromiCloud))
        retrieveDataFromiCloudLabel.isUserInteractionEnabled = true
        retrieveDataFromiCloudLabel.addGestureRecognizer(retrieveTap)
    }
    
    func overwriteTagsDataInDatabase(allTags: String){

        let recordID = CKRecord.ID(recordName: "TagsDataString")
        
        database.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                
                //update your record here
                record.setValue(allTags, forKey: "Tags")
                
                self.database.save(record) { (record, error) in
                    if error != nil {
                        self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                    }
                    guard record != nil else {return}
                    print("record saved!")
                    self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                }
            }else{
                let newTagsRecord = CKRecord(recordType: "TagsDataString", recordID: CKRecord.ID(recordName: "TagsDataString"))
                newTagsRecord.setValue(allTags, forKey: "Tags")
                
                self.database.save(newTagsRecord) { (record, error) in
                    if error != nil {
                        self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                    }
                    guard record != nil else {return}
                    print("record saved!")
                    self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                }
            }
        }
    }
    
    func overwriteDirectoriesDataInDatabase(allDirectories: String){
        
        let recordID = CKRecord.ID(recordName: "DirectoriesDataString")
        
        database.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                
                //update your record here
                record.setValue(allDirectories, forKey: "Tags")
                
                self.database.save(record) { (record, error) in
                    if error != nil {
                        self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                    }
                    guard record != nil else {return}
                    print("record saved!")
                    self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                }
            }else{
                let newTagsRecord = CKRecord(recordType: "DirectoriesDataString", recordID: CKRecord.ID(recordName: "DirectoriesDataString"))
                newTagsRecord.setValue(allDirectories, forKey: "Directories")
                
                self.database.save(newTagsRecord) { (record, error) in
                    if error != nil {
                        self.showAlertWith(title: "Failed!", message: "Something went wrong while saving your data to iCloud")
                    }
                    guard record != nil else {return}
                    print("record saved!")
                    self.showAlertWith(title: "Success!", message: "Your data is now backed up")
                }
            }
        }
    }
    
    @objc func saveDataToiCloud(){
        do{
            let allTagsData = try String(contentsOf: FileManager.tagsFileURL, encoding: .utf8)
            let allDirectoriesData = try String(contentsOf: FileManager.directoriesURL, encoding: .utf8)
            
            overwriteTagsDataInDatabase(allTags: allTagsData)
            overwriteDirectoriesDataInDatabase(allDirectories: allDirectoriesData)
            
        }catch{
            print("Couldn't fetch data to save")
        }
    }
    
    @objc func retrieveDataFromiCloud(){
        let recordID = CKRecord.ID(recordName: "TagsDataString")
        
        database.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                do{
                    let tagsRecord = record.object(forKey: "Tags")
                    let tagsString = tagsRecord as! String
                    
                    let tagsData = tagsString.data(using: .utf8) as! Data
                    let decoder = JSONDecoder()
                    let decodedJson = try decoder.decode([Images].self, from: tagsData)
                    let encoder = JSONEncoder()
                    
                    let encodedJSON = try encoder.encode(decodedJson)
                    try encodedJSON.write(to: FileManager.tagsFileURL, options: .atomic)
                    self.showAlertWith(title: "Success!", message: "Retrieved your data successfully")
                }catch{
                    print("Error call")
                    self.showAlertWith(title: "Failed!", message: "Something went wrong while trying to retrieve data")
                }
            }else{
                self.showAlertWith(title: "Failed", message: "Data not found in iCloud")
            }
        }

    }
}
