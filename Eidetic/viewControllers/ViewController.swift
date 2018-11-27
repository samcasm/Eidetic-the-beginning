//
//  ViewController.swift
//  Eidetic
//
//  Created by user145467 on 11/15/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class ViewController: UIViewController {
    
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    var directoryName: String!
    var _selectedCells: NSMutableArray = []
    
    @IBOutlet var addTagButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!

    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    deinit {
        directoryName = nil
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let width = (view.frame.size.width - 20) / 3
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        thumbnailSize = CGSize(width: width, height: width)
        
        // Add button to the navigation bar if the asset collection supports adding content.
        if assetCollection == nil || assetCollection.canPerform(.addContent) {
            navigationItem.rightBarButtonItem = addButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
        searchBar.delegate = self
        self.hideKeyboardWhenTappedAround()
        navigationController?.isToolbarHidden = true
        toolbarItems = [addTagButton]
        addTagButton.isEnabled = false
        
        PHPhotoLibrary.shared().register(self)
        
        // If we get here without a segue, it's because we're visible at app launch,
        // so match the behavior of segue from the default "All Photos" view.
        if directoryName == nil{
            if fetchResult == nil {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            }
        }else{
            do{
                let allDirectories = try [Directory]()
                let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds!), options: nil)
            }catch{
                print("Error while directory details display \(error)")
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
        
    }
    
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    // MARK: UI Actions
    
   
    @IBAction func addTagPopOver(_ sender: UIBarButtonItem) {
        showInputDialog(title: "Add a tag",
                        subtitle: "Please enter a new tag below",
                        actionTitle: "Add",
                        cancelTitle: "Cancel",
                        inputKeyboardType: .default)
        { (inputTag:String?) in
            print("The new number is \(inputTag ?? "")")
            
            var allImagesWithTags = try? [Images]()
            let selectedCellPaths = self._selectedCells as NSArray as! [IndexPath]
            var selectedAssetsIds : [String] = []

            for cell in selectedCellPaths {
                let photoAsset = self.fetchResult.object(at: cell.item) as PHAsset
                selectedAssetsIds.append(photoAsset.localIdentifier)
            }
            for (i, image) in allImagesWithTags!.enumerated() {
                if selectedAssetsIds.contains(image.id) {
                    allImagesWithTags?[i].tags.insert(inputTag!)
                }
            }
            try? allImagesWithTags?.save()
        }
    }
    
    @IBAction func multipleSelectToggle(_ sender: Any) {
        collectionView.allowsMultipleSelection = !collectionView.allowsMultipleSelection
       
        
        let selectedCells: NSArray = _selectedCells
        for cellPath in selectedCells {
            let selectedCell : UICollectionViewCell = collectionView.cellForItem(at: cellPath as! IndexPath)!
            selectedCell.layer.borderWidth = 0
        }
         _selectedCells.removeAllObjects()
        
        if collectionView.allowsMultipleSelection {
            selectButton.title = "Cancel"
            navigationController?.isToolbarHidden = false
            searchBar.isUserInteractionEnabled = false
            
        }else{
            selectButton.title = "Select"
            navigationController?.isToolbarHidden = true
            searchBar.isUserInteractionEnabled = true
            
        }
        
        
        navigationController?.isToolbarHidden = collectionView.allowsMultipleSelection
        
       
    }
  
    @IBAction func addAsset(_ sender: AnyObject?) {
        
        // Create a dummy image of a random solid color and random orientation.
        let size = (arc4random_uniform(2) == 0) ?
            CGSize(width: 400, height: 300) :
            CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(hue: CGFloat(arc4random_uniform(100))/100,
                    saturation: 1, brightness: 1, alpha: 1).setFill()
            context.fill(context.format.bounds)
        }
        
        // Add it to the photo library.
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let assetCollection = self.assetCollection {
                let addAssetRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
            }
        }, completionHandler: {success, error in
            if !success { print("error creating asset") }
        })
    }
    
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let destination = segue.destination as? AssetViewController
                else { fatalError("unexpected view controller for segue") }
            
        let indexPath = collectionView!.indexPath(for: sender as! UICollectionViewCell)!
        destination.asset = fetchResult.object(at: indexPath.item)
        destination.assetCollection = assetCollection
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "assetView", collectionView.allowsMultipleSelection == true {
            return false
        }
        return true
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchResult == nil) {
            self.collectionView.setEmptyMessage("Nothing to show :(")
            return 0
        } else {
            self.collectionView.restore()
            return fetchResult.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)
        
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCell.self), for: indexPath) as? PhotoCell
            else { fatalError("unexpected cell in collection view") }
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if asset.mediaSubtypes.contains(.photoLive) {
            cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell : UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
        if collectionView.allowsMultipleSelection == true {
            _selectedCells.add(indexPath)
            navigationController?.isToolbarHidden = false
            addTagButton.isEnabled = _selectedCells.count > 0 ? true : false
            selectedCell.layer.borderWidth = 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
         let unselectedCell : UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
        if collectionView.allowsMultipleSelection == true {
            _selectedCells.remove(indexPath)
            addTagButton.isEnabled = _selectedCells.count < 2 ? false: true
            unselectedCell.layer.borderWidth = 0
        }
    }
    
    
}

// MARK: PHPhotoLibraryChangeObserver
extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if !searchText.isEmpty {
            do{
                var allImages = try [Images]()
                if directoryName != nil{
                    let allDirectories = try [Directory]()
                    let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                    allImages = allImages.filter{(image: Images) -> Bool in
                        return imageIds!.contains(image.id)
                    }
                }
                var filteredImages: [Images]
                filteredImages = allImages.filter { (image: Images) -> Bool in
                    for imageTag in image.tags{
                        if imageTag.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil{
                            return true
                        }
                    }
                    return false
                }
                
                if filteredImages.count == 0 {
                    fetchResult = nil
                }else{
                    let imageIds = filteredImages.map({$0.id})
                    fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: imageIds, options: nil)
                }
            }catch{
                print("Search error: \(error)")
            }
        }else{
            do{
                if(directoryName == nil){
                    let allPhotosOptions = PHFetchOptions()
                    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
                }else{
                    let allDirectories = try [Directory]()
                    let imageIds = allDirectories.first{$0.id == directoryName}?.imageIDs
                    fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(imageIds!), options: nil)
                }
            }catch{
                print("Search Error \(error)")
            }
        }
        collectionView.reloadData()
    }
}



