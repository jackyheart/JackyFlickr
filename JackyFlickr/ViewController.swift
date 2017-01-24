//
//  ViewController.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 23/1/17.
//
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var dataArray:[FlickrItem] = []
    let cache = NSCache<NSString, UIImage>()
    var currentPage = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.loadPublicPhotoFeed()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Photo Feed
    
    func loadPublicPhotoFeed() {
    
        Flickr.shared.getPublicPhotoFeed(success: { (flickerItems) in
            
            self.dataArray.append(contentsOf: flickerItems)
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
            }, failure: { (error) in
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
                    alert.addAction(okAction)
                    
                    self.present(alert, animated: true, completion: nil)
                }
        })
    }

    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PublicCellIdentifier", for: indexPath) as! PhotoCell
        
        let flickrItem = self.dataArray[indexPath.row]
        
        if let cachedImage = self.cache.object(forKey: flickrItem.urlString as NSString) {
        
            cell.imgView.image = cachedImage
            
        } else {
        
            guard let url = URL(string: flickrItem.urlString) else {
                return cell
            }
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
                DispatchQueue.main.async {
                    if let data = data {
                        
                        if let image = UIImage(data: data) {
                        
                            cell.imgView.image = image
                            
                            //save to cache
                            self.cache.setObject(image, forKey: flickrItem.urlString as NSString)
                        }
                    }
                }
                
            }).resume()
        }
        
        return cell
    }
    
    //MARK: - UIScrollViewDelegate
    
    //http://stackoverflow.com/questions/39015228/detect-when-uitableview-has-scrolled-to-the-bottom
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        let  height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom < height {
            self.loadPublicPhotoFeed()
        }
    }
}

