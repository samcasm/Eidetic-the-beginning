import UIKit

class DirectoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        do{
            let allDirectories = try [Directory]()
            return allDirectories.count
        }catch{
            print("Error while counting directories: \(error)")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DirectoryCell", for: indexPath as IndexPath) as! DirectoryCell
            do{
                var allDirectories = try [Directory]()
                // get a reference to our storyboard cell
                
                // Use the outlet in our custom class to get a reference to the UILabel in the cell
                cell.directoryName.text = allDirectories[indexPath.item].id
                cell.backgroundColor = UIColor.green // make cell more visible in our example project
                
            }catch{
                print("Error while assigning directories: \(error)")
            }
        return cell
        }
        
        // MARK: - UICollectionViewDelegate protocol
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // handle tap events
            print("You selected cell #\(indexPath.item)!")
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DirectoryDetailsSegue"{
            if let dest = segue.destination as? ViewController, let index = collectionView.indexPathsForSelectedItems?.first {
                var allDirectories = try? [Directory]()
                dest.directoryName = allDirectories?[index.row].id
            }
        }
    }
}
    

