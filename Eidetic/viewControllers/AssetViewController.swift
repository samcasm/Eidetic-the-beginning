//
//  AssetViewController.swift
//  Eidetic
//
//  Created by user145467 on 11/17/18.
//  Copyright © 2018 user145467. All rights reserved.
//


import UIKit
import Photos
import PhotosUI

class AssetViewController: UIViewController {
    
    var asset: PHAsset!
    var assetCollection: PHAssetCollection!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addTagTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addtagButton: UIButton!
    @IBOutlet weak var makeFolderCheckbox: UIButton!
    
    
    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var space: UIBarButtonItem!
    @IBOutlet var trashButton: UIBarButtonItem!
    @IBOutlet var favoriteButton: UIBarButtonItem!
    
    fileprivate var playerLayer: AVPlayerLayer!
    fileprivate var isPlayingHint = false
    
    fileprivate lazy var formatIdentifier = Bundle.main.bundleIdentifier!
    fileprivate let formatVersion = "1.0"
    fileprivate lazy var ciContext = CIContext()
    
    @IBOutlet weak var tagListView: TagListView!
    
    // MARK: UIViewController / Lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        livePhotoView.delegate = self
        addTagTextField.delegate = self
        tagListView.delegate = self
        self.hideKeyboardWhenTappedAround()
        PHPhotoLibrary.shared().register(self)
        
        let dateString = asset.creationDate?.toString(format: "dd MMMM, YYYY")
        
        self.navigationItem.title = dateString
        
        displayTags()
        
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addtagButton.isEnabled = false
        
        // Set the appropriate toolbarItems based on the mediaType of the asset.
        if asset.mediaType == .video {
            
            toolbarItems = [favoriteButton, space, playButton, space, trashButton]
            navigationController?.isToolbarHidden = false
           
        } else {
            // In iOS, present both stills and Live Photos the same way, because
            // PHLivePhotoView provides the same gesture-based UI as in Photos app.
            toolbarItems = [favoriteButton, space, trashButton]
            navigationController?.isToolbarHidden = false
        }
        
        // Enable editing buttons if the asset can be edited.
        editButton.isEnabled = asset.canPerform(.content)
        favoriteButton.isEnabled = asset.canPerform(.properties)
        favoriteButton.title = asset.isFavorite ? "♥︎" : "♡"
        
        // Enable the trash button if the asset can be deleted.
        if assetCollection != nil {
            trashButton.isEnabled = assetCollection.canPerform(.removeContent)
        } else {
            trashButton.isEnabled = asset.canPerform(.delete)
        }
        
        // Make sure the view layout happens before requesting an image sized to fit the view.
        view.layoutIfNeeded()
        updateImage()
    }
    
    func displayTags(){
        tagListView.removeAllTags()
        do{
            let assetId = asset.localIdentifier
            let allImagesTagsData = try [Images]()
            let assetIndex = allImagesTagsData.firstIndex(where: { $0.id == assetId })
            
            if assetIndex != nil{
                let arrayOfTags = Array(allImagesTagsData[assetIndex!].tags)
                tagListView.addTags(arrayOfTags)
                tagListView.textFont = UIFont.systemFont(ofSize: 20)
            }
            
            
        }catch{
            print("Tag Display View Error: \(error)")
        }
    }
    
    func addTag(){
        do {
            var allImagesTagsData = try [Images]()
            let assetId: String = asset.localIdentifier
            let newTag: String = String(addTagTextField.text!)
            var allDirectories = try [Directory]()
            
            if let i = allDirectories.firstIndex(where: { $0.id == newTag }) {
                allDirectories[i].imageIDs.insert(assetId)
            }
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].tags.insert(newTag)
            }else{
                let newAsset: Images = Images(id: assetId, tags: [newTag])
                allImagesTagsData.append(newAsset)
            }
            
            try allImagesTagsData.save()
            addTagTextField.text = ""
            self.hideKeyboardWhenTappedAround()
            
            if(makeFolderCheckbox.isSelected){
                
                let isDirectoryExists = allDirectories.map{ $0.id }.contains(newTag) == true
                var directory: Directory
                let directoryIndex: Int
                
                if isDirectoryExists {
                    directoryIndex = allDirectories.firstIndex(where: { $0.id == newTag })!
                }else{
                    directory = Directory(id: newTag, imageIDs:[])
                    allDirectories.append(directory)
                    directoryIndex = allDirectories.count - 1
                }
                allImagesTagsData.forEach{
                    if($0.tags.contains(newTag)){
                        isDirectoryExists ? allDirectories[directoryIndex].imageIDs.insert($0.id) : allDirectories[directoryIndex].imageIDs.insert($0.id)
                    }
                }
                
            }
            try allDirectories.save()
            makeFolderCheckbox.isSelected = false
            
            displayTags()
            
            
        }catch{
            print("Could not add tag to asset: \(error)")
        }
    }
    
    // MARK: UI Actions
    
    
    @IBAction func makeFolderToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func addTagToAsset(_ sender: Any){
        addTag()
    }
    
    @IBAction func editAsset(_ sender: UIBarButtonItem) {
        // Use a UIAlertController to display editing options to the user.
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        #if os(iOS)
        alertController.modalPresentationStyle = .popover
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
            popoverController.permittedArrowDirections = .up
        }
        #endif
        
        // Add a Cancel action to dismiss the alert without doing anything.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                                style: .cancel, handler: nil))
        
        // Allow editing only if the PHAsset supports edit operations.
        if asset.canPerform(.content) {
            // Add actions for some canned filters.
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Sepia Tone", comment: ""),
                                                    style: .default, handler: getFilter("CISepiaTone")))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Chrome", comment: ""),
                                                    style: .default, handler: getFilter("CIPhotoEffectChrome")))
            
            // Add actions to revert any edits that have been made to the PHAsset.
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Revert", comment: ""),
                                                    style: .default, handler: revertAsset))
        }
        // Present the UIAlertController.
        present(alertController, animated: true)
        
    }
    
    @IBAction func removeAsset(_ sender: AnyObject) {
        let completion = { (success: Bool, error: Error?) -> () in
            if success {
                PHPhotoLibrary.shared().unregisterChangeObserver(self)
                DispatchQueue.main.sync {
                    _ = self.navigationController!.popViewController(animated: true)
                }
            } else {
                print("can't remove asset")
            }
        }
        
        if assetCollection != nil {
            // Remove asset from album
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest(for: self.assetCollection)!
                request.removeAssets([self.asset] as NSArray)
            }, completionHandler: completion)
        } else {
            // Delete asset from library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([self.asset] as NSArray)
            }, completionHandler: completion)
        }
        
    }
    
    @IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset)
            request.isFavorite = !self.asset.isFavorite
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.sync {
                    sender.title = self.asset.isFavorite ? "♥︎" : "♡"
                }
            } else {
                print("can't set favorite")
            }
        })
    }
    
    // MARK: Image display
    
    var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: imageView.bounds.width * scale,
                      height: imageView.bounds.height * scale)
//        return CGSize(width: 400, height: 300)
    }
    
    func updateImage() {
        if asset.mediaSubtypes.contains(.photoLive) {
            updateLivePhoto()
        } else {
            updateStaticImage()
        }
    }
    
    func updateLivePhoto() {
        // Prepare the options to pass when fetching the live photo.
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            
        }
        
        // Request the live photo for the asset from the default PHImageManager.
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { livePhoto, info in
            
            // If successful, show the live photo view and display the live photo.
            guard let livePhoto = livePhoto else { return }
            
            // Now that we have the Live Photo, show it.
            self.imageView.isHidden = true
            self.livePhotoView.isHidden = false
            self.livePhotoView.livePhoto = livePhoto
            
            if !self.isPlayingHint {
                // Playback a short section of the live photo; similar to the Photos share sheet.
                self.isPlayingHint = true
                self.livePhotoView.startPlayback(with: .hint)
            }
            
        })
    }
    
    func updateStaticImage() {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            
        }
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            
            // If successful, show the image view and display the image.
            guard let image = image else { return }
            
            // Now that we have the image, show it.
            self.livePhotoView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = image
            
            self.resizeImageViewToImageSize(self.imageView)
        })
    }
    
    
    // Image Resizing
    func resizeImageViewToImageSize(_ imageView:UIImageView) {
        
        let maxWidth = view.frame.size.width
        let maxHeight = view.frame.size.height
        
        var widthRatio = imageView.bounds.size.width / imageView.image!.size.width
        
        if widthRatio < 1 {
            widthRatio = 1 / widthRatio
        }
        
        var heightRatio = imageView.bounds.size.height / imageView.image!.size.height
        
        if heightRatio < 1 {
            heightRatio = 1 / widthRatio
        }
        
        let scale = min(widthRatio, heightRatio)
        
        let maxWidthRatio = maxWidth / imageView.bounds.size.width
        let maxHeightRatio = maxHeight / imageView.bounds.size.height
        let maxScale = min(maxWidthRatio, maxHeightRatio)
        
        let properScale = min(scale, maxScale)
        
        let imageWidth = properScale * imageView.image!.size.width
        let imageHeight = properScale * imageView.image!.size.height
        print("\(imageWidth) - \(imageHeight)")
        
        imageView.frame = CGRect(x: 0,
                                 y: 70,
                                 width: imageWidth,
                                 height: imageHeight)
        imageView.center.x = view.center.x
    }
    
    // MARK: Asset editing
    
    func revertAsset(sender: UIAlertAction) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset)
            request.revertAssetContentToOriginal()
        }, completionHandler: { success, error in
            if !success { print("can't revert asset") }
        })
    }
    
    // Returns a filter-applier function for the named filter, to be passed as a UIAlertAction handler
    func getFilter(_ filterName: String) -> (UIAlertAction) -> () {
        func applyFilter(_: UIAlertAction) {
            // Set up a handler to make sure we can handle prior edits.
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {
                $0.formatIdentifier == self.formatIdentifier && $0.formatVersion == self.formatVersion
            }
            
            // Prepare for editing.
            asset.requestContentEditingInput(with: options, completionHandler: { input, info in
                guard let input = input
                    else { fatalError("can't get content editing input: \(info)") }
                
                // This handler gets called on the main thread; dispatch to a background queue for processing.
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    // Create adjustment data describing the edit.
                    let adjustmentData = PHAdjustmentData(formatIdentifier: self.formatIdentifier,
                                                          formatVersion: self.formatVersion,
                                                          data: filterName.data(using: .utf8)!)
                    
                    /* NOTE:
                     This app's filter UI is fire-and-forget. That is, the user picks a filter,
                     and the app applies it and outputs the saved asset immediately. There's
                     no UI state for having chosen but not yet committed an edit. This means
                     there's no role for reading adjustment data -- you do that to resume
                     in-progress edits, and this sample app has no notion of "in-progress".
                     
                     However, it's still good to write adjustment data so that potential future
                     versions of the app (or other apps that understand our adjustement data
                     format) could make use of it.
                     */
                    
                    // Create content editing output, write the adjustment data.
                    let output = PHContentEditingOutput(contentEditingInput: input)
                    output.adjustmentData = adjustmentData
                    
                    // Select a filtering function for the asset's media type.
                    let applyFunc: (String, PHContentEditingInput, PHContentEditingOutput, @escaping () -> ()) -> ()
                    if self.asset.mediaSubtypes.contains(.photoLive) {
                        applyFunc = self.applyLivePhotoFilter
                    } else if self.asset.mediaType == .image {
                        applyFunc = self.applyPhotoFilter
                    } else {
                        applyFunc = self.applyVideoFilter
                    }
                    
                    // Apply the filter.
                    applyFunc(filterName, input, output, {
                        // When rendering is done, commit the edit to the Photos library.
                        PHPhotoLibrary.shared().performChanges({
                            let request = PHAssetChangeRequest(for: self.asset)
                            request.contentEditingOutput = output
                        }, completionHandler: { success, error in
                            if !success { print("can't edit asset") }
                        })
                    })
                }
            })
        }
        return applyFilter
    }
    
    func applyPhotoFilter(_ filterName: String, input: PHContentEditingInput, output: PHContentEditingOutput, completion: () -> ()) {
        
        // Load the full size image.
        guard let inputImage = CIImage(contentsOf: input.fullSizeImageURL!)
            else { fatalError("can't load input image to edit") }
        
        // Apply the filter.
        let outputImage = inputImage
            .oriented(forExifOrientation: input.fullSizeImageOrientation)
            .applyingFilter(filterName)
        
        // Write the edited image as a JPEG.
        do {
            try self.ciContext.writeJPEGRepresentation(of: outputImage,
                                                       to: output.renderedContentURL, colorSpace: inputImage.colorSpace!, options: [:])
        } catch let error {
            fatalError("can't apply filter to image: \(error)")
        }
        completion()
    }
    
    func applyLivePhotoFilter(_ filterName: String, input: PHContentEditingInput, output: PHContentEditingOutput, completion: @escaping () -> ()) {
        
        // This app filters assets only for output. In an app that previews
        // filters while editing, create a livePhotoContext early and reuse it
        // to render both for previewing and for final output.
        guard let livePhotoContext = PHLivePhotoEditingContext(livePhotoEditingInput: input)
            else { fatalError("can't get live photo to edit") }
        
        livePhotoContext.frameProcessor = { frame, _ in
            return frame.image.applyingFilter(filterName)
        }
        livePhotoContext.saveLivePhoto(to: output) { success, error in
            if success {
                completion()
            } else {
                print("can't output live photo")
            }
        }
    }
    
    func applyVideoFilter(_ filterName: String, input: PHContentEditingInput, output: PHContentEditingOutput, completion: @escaping () -> ()) {
        // Load AVAsset to process from input.
        guard let avAsset = input.audiovisualAsset
            else { fatalError("can't get AV asset to edit") }
        
        // Set up a video composition to apply the filter.
        let composition = AVVideoComposition(
            asset: avAsset,
            applyingCIFiltersWithHandler: { request in
                let filtered = request.sourceImage.applyingFilter(filterName)
                request.finish(with: filtered, context: nil)
        })
        
        // Export the video composition to the output URL.
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
            else { fatalError("can't set up AV export session") }
        export.outputFileType = AVFileType.mov
        export.outputURL = output.renderedContentURL
        export.videoComposition = composition
        export.exportAsynchronously(completionHandler: completion)
        
    }
}

//TagListView delegate methods
extension AssetViewController: TagListViewDelegate {
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        
        do{
            let assetId = asset.localIdentifier
            var allImagesTagsData = try [Images]()
            var allDirectories = try [Directory]()
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].tags.remove(title)
                try allImagesTagsData.save()
            }
            
            if let i = allDirectories.firstIndex(where: { $0.id == title }) {
                allDirectories[i].imageIDs.remove(assetId)
                try allDirectories.save()
            }
            sender.removeTagView(tagView)
            
        }catch{
            print("Delete Tag Error: \(error)")
        }
    }
}


// MARK: PHPhotoLibraryChangeObserver
extension AssetViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        DispatchQueue.main.sync {
            // Check if there are changes to the asset we're displaying.
            guard let details = changeInstance.changeDetails(for: asset) else { return }
            
            // Get the updated asset.
            asset = details.objectAfterChanges as? PHAsset
            
            // If the asset's content changed, update the image and stop any video playback.
            if details.assetContentChanged {
                updateImage()
                
                playerLayer?.removeFromSuperlayer()
                playerLayer = nil
            }
        }
    }
}

// MARK: PHLivePhotoViewDelegate
extension AssetViewController: PHLivePhotoViewDelegate {
    func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        isPlayingHint = (playbackStyle == .hint)
    }
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        isPlayingHint = (playbackStyle == .hint)
    }
}

extension AssetViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if textField.text?.hasAlphanumeric == true, newString.count > 0{
            addtagButton.isEnabled = true
        }else{
            addtagButton.isEnabled = false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addTagTextField.resignFirstResponder()
        addTag()
        return true
    }
}


