//
//  DetailedViewController.swift
//  Eidetic
//
//  Created by user147964 on 1/27/19.
//  Copyright © 2019 user145467. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import AVKit
import EEZoomableImageView
import INSPhotoGallery

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}


class DetailedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var fetchResult: PHFetchResult<PHAsset>!
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    var startIndex: Int = 0
    var indexForCell: IndexPath!
    var phasset: PHAsset!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    
    @IBOutlet weak var detailedCollectionView: UICollectionView!
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    
    lazy var photos: [INSPhotoViewable] = {
        var allPhotos: [INSPhoto] = Array()
        fetchResult.enumerateObjects({ (asset, index, stop) in
            let image = self.requestImageForPHAsset(asset: asset)
            allPhotos.append(INSPhoto(image: image, thumbnailImage: nil))
        })
        
        return allPhotos
//        return [
//            INSPhoto(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/13-3f15416ddd11d38619289335fafd498d.jpg"), thumbnailImage: UIImage(named: "thumbnailImage")!),
//            INSPhoto(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/13-3f15416ddd11d38619289335fafd498d.jpg"), thumbnailImage: UIImage(named: "thumbnailImage")!),
//            INSPhoto(image: UIImage(named: "fullSizeImage")!, thumbnailImage: UIImage(named: "thumbnailImage")!),
//            ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
        imageManager.allowsCachingHighQualityImages = true
        PHPhotoLibrary.shared().register(self)
        
        if fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            
        }
        navigationController?.isToolbarHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.detailedCollectionView.scrollToItem(at:IndexPath(item: indexForCell.item, section: 0), at: .centeredHorizontally, animated: false)
        detailedCollectionView.layoutSubviews()
        detailedCollectionView.isPagingEnabled = true
        
        setFavoriteButton(assetID: phasset.localIdentifier)
        let dateString = phasset.creationDate?.toString(format: "dd MMMM, YYYY")
        self.navigationItem.title = dateString
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
        
        toolbarItems = [favoriteButton]
        navigationController?.isToolbarHidden = false
        
        self.detailedCollectionView.scrollToItem(at:IndexPath(item: indexForCell.item, section: 0), at: .centeredHorizontally, animated: false)
        detailedCollectionView.layoutSubviews()
        detailedCollectionView.isPagingEnabled = true
    }
    
    func fetchCurrentCellFromCollectionView() -> DetailedCollectionViewCell{
        let visibleRect = CGRect(origin: detailedCollectionView.contentOffset, size: detailedCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = detailedCollectionView.indexPathForItem(at: visiblePoint)
        let cell = detailedCollectionView.cellForItem(at: IndexPath(item: visibleIndexPath![1], section: 0)) as! DetailedCollectionViewCell
        print(cell)
        return cell
    }
    
    func playVideo(){
        PHCachingImageManager().requestAVAsset(forVideo: phasset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset
            
            DispatchQueue.main.async {
                let player = AVPlayer(url: asset.url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
    }
    
    //MARK: Image fullscreen on tap
    
    var imageViewScale: CGFloat = 1.0
    let maxScale: CGFloat = 4.0
    let minScale: CGFloat = 1.0
    
    @objc func pinchGesture(recognizer: UIPinchGestureRecognizer) {
        
        if recognizer.state == .began || recognizer.state == .changed {
            let pinchScale: CGFloat = recognizer.scale
            
            if imageViewScale * pinchScale < maxScale && imageViewScale * pinchScale > minScale {
                imageViewScale *= pinchScale
                self.view.transform = (self.view.transform.scaledBy(x: pinchScale, y: pinchScale))
            }
            recognizer.scale = 1.0
        }
        //        case .ended:
        //                // Nice animation to scale down when releasing the pinch.
        //                // OPTIONAL
        //                UIView.animate(withDuration: 0.2, animations: {
        //                    view.transform = CGAffineTransform.identity
        //                })
    }
    
    func addSwipe(view: UIImageView) {
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe))
            gesture.direction = direction
            view.addGestureRecognizer(gesture)
        }
    }
    
    func requestImageForPHAsset(asset: PHAsset) -> UIImage{
        var assetImage: UIImage = UIImage()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            assetImage = image!
        })
        return assetImage
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print(sender.direction)
            switch sender.direction {
            case UISwipeGestureRecognizer.Direction.right:
                let imageView = sender.view as! UIImageView
                let cell = fetchCurrentCellFromCollectionView()
                let cellIndex = detailedCollectionView.indexPath(for: cell) as! IndexPath
                if cellIndex.item > 0 && cellIndex.item < fetchResult.count {
                    let prevCellImage = requestImageForPHAsset(asset: fetchResult[cellIndex.item - 1])
                    imageView.image = prevCellImage
                }
            case UISwipeGestureRecognizer.Direction.down:
                dismissFullscreenImage(sender)
            case UISwipeGestureRecognizer.Direction.left:
                print("Swiped left")
            default:
                break
            }
        
    }
    
    func createFullscreenImageView(imageView: UIImageView){
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        addSwipe(view: newImageView)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture))
        newImageView.addGestureRecognizer(pinchGesture)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        if phasset.mediaType == .video {
            playVideo()
        }else{
            let imageView = sender.view as! UIImageView
            createFullscreenImageView(imageView: imageView)
        }
    }
    
    @objc func dismissFullscreenImage(_ sender: UIGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    
   // Favorite functionality
    @IBAction func favouriteButtonAction(_ sender: UIBarButtonItem) {
        let cell = fetchCurrentCellFromCollectionView()
        toggleFavoriteButton(assetID: cell.assetIdentifier)
    }
    
    //MARK: Favorites functionality
    func toggleFavoriteButton(assetID: String){
        do{
            let assetId = assetID
            var allImagesTagsData = try [Images]()
            var allDirectories = try [Directory]()
            var isFav: Bool = true
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                allImagesTagsData[i].isFavorite = !allImagesTagsData[i].isFavorite
                isFav = allImagesTagsData[i].isFavorite
                try allImagesTagsData.save()
                favoriteButton.image = allImagesTagsData[i].isFavorite ? UIImage(named: "favorite") : UIImage(named: "unfavorite")
            }else{
                let newAsset: Images = Images(id: assetId, tags: [], isFavorite: true)
                allImagesTagsData.append(newAsset)
                try allImagesTagsData.save()
                favoriteButton.image = UIImage(named: "favorite")
            }
            
            if let i = allDirectories.firstIndex(where: { $0.id == "favorites" }) {
                if isFav == true{
                    allDirectories[i].imageIDs.insert(assetId)
                    try allDirectories.save()
                }else{
                    allDirectories[i].imageIDs.remove(assetId)
                    try allDirectories.save()
                }
                
            }
        }catch{
            print("Failed to set favorite toggle")
        }
    }
    
    func setFavoriteButton(assetID: String){
        do{
            let assetId = assetID
            var allImagesTagsData = try [Images]()
            
            if let i = allImagesTagsData.firstIndex(where: { $0.id == assetId }) {
                favoriteButton.image = allImagesTagsData[i].isFavorite ? UIImage(named: "favorite") : UIImage(named: "unfavorite")
            }else{
                favoriteButton.image = UIImage(named: "unfavorite")
            }
        }catch{
            print("Failed to set favorite toggle")
        }
    }
    
    
    func updateImage() {
        updateStaticImage()
    }
    
    func updateStaticImage() {
        // Prepare the options to pass when fetching the (photo, or video preview) image.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
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
    
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = self.detailedCollectionView.contentOffset
        visibleRect.size = self.detailedCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath: NSIndexPath = self.detailedCollectionView.indexPathForItem(at: visiblePoint)! as NSIndexPath
        
        guard let indexPath: NSIndexPath = visibleIndexPath else { return }
        print(indexPath)
        phasset = fetchResult.object(at: indexPath.item)
        
        setFavoriteButton(assetID: phasset.localIdentifier)
        
        let dateString = phasset.creationDate?.toString(format: "dd MMMM, YYYY")
        self.navigationItem.title = dateString
    }
    
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchResult == nil) {
            self.detailedCollectionView.setEmptyMessage("Nothing to show :(")
            return 0
        } else {
            self.detailedCollectionView.restore()
            return fetchResult.count
        }
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue a GridViewCell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! DetailedCollectionViewCell
        let asset = fetchResult.object(at: indexPath.item)
        var targetSize: CGSize {
            let scale = UIScreen.main.scale
            return CGSize(width: cell.imageView.bounds.width * scale,
                          height: cell.imageView.bounds.height * scale)
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.assetIdentifier = asset.localIdentifier
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.assetIdentifier == asset.localIdentifier {
                cell.assetImage = image?.fixedOrientation()
//                self.resizeImageViewToImageSize(cell.imageView)

            }
        })
        
//        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
//        cell.imageView.addGestureRecognizer(pictureTap)
//        cell.imageView.isUserInteractionEnabled = true
        
        let stackViewTopConstraint = NSLayoutConstraint(item: cell.addTagStackView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 30)
        let tagsCollectionViewBottomConstraint = NSLayoutConstraint(item: cell.tagsCollectionView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([stackViewTopConstraint, tagsCollectionViewBottomConstraint])
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        let cell = collectionView.cellForItem(at: indexPath) as! DetailedCollectionViewCell
        let currentPhoto = photos[indexPath.row]
        let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell)
        
        galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            if let index = self?.photos.index(where: {$0 === photo}) {
                let indexPath = IndexPath(item: index, section: 0)
                return collectionView.cellForItem(at: indexPath) as? DetailedCollectionViewCell
            }
            return nil
        }
        present(galleryPreview, animated: true, completion: nil)
    }
    
}

extension DetailedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}



// MARK: PHPhotoLibraryChangeObserver
extension DetailedViewController: PHPhotoLibraryChangeObserver {
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
                guard let collectionView = self.detailedCollectionView else { fatalError() }
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
                detailedCollectionView!.reloadData()
            }
            resetCachedAssets()
        }
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
        let visibleRect = CGRect(origin: detailedCollectionView!.contentOffset, size: detailedCollectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in detailedCollectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in detailedCollectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let screenWidth = UIScreen.main.bounds.size.width
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: CGSize(width: screenWidth, height: screenWidth), contentMode: .aspectFit, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: CGSize(width: screenWidth, height: screenWidth), contentMode: .aspectFit, options: nil)
        
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
    
}
