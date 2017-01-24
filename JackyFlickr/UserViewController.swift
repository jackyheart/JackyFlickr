//
//  UserViewController.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 24/1/17.
//
//

import UIKit

class UserViewController: UIViewController, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dataArray:[FlickrItem] = []
    let cache = NSCache<NSString, UIImage>()
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.collectionView.isHidden = true
        self.loginButton.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //observe for access token
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccessTokenNotification(notification:)), name: NSNotification.Name(rawValue: "AccessTokenNotification"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //un-register notification
        NotificationCenter.default.removeObserver(self)
        
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBAction
    
    @IBAction func login(_ sender: Any) {
        
        Flickr.shared.login { (error) in
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
                alert.addAction(okAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - User Photo Feed
    
    func loadUserPhotos() {
        
        self.activityIndicator.startAnimating()
        
        Flickr.shared.retrieveUserPhotos(page: self.currentPage, complete: { (items) in
            
            DispatchQueue.main.async {
                
                self.activityIndicator.stopAnimating()
                
                if items.count > 0 {
                    
                    if self.currentPage == 1 {
                        //clear content if it is first page
                        self.dataArray = items
                    } else {
                        self.dataArray.append(contentsOf: items)
                    }
                    
                    self.currentPage = self.currentPage + 1
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
    //MARK: - NSNotificationCenter
    
    func handleAccessTokenNotification(notification:Notification) {
        
        guard let tokenDict = notification.object as? [String:String] else {
            print("notification object unparsable")
            return
        }
        
        Flickr.shared.requestAcessToken(tokenDict: tokenDict, success: { (userDict) in
            
            DispatchQueue.main.async {
                
                guard let userDict = userDict else {
                    print("userDict is nil")
                    return
                }
                
                print("userDict: \(userDict)")
                
                self.collectionView.isHidden = false
                self.loginButton.isHidden = true
                self.addNavigationBarButtons()//logout and upload button
                
                self.currentPage = 1//back to page 1
                self.loadUserPhotos()
            }
            
        }) { (error) in
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
                alert.addAction(okAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - UINavigationBar Buttons
    
    func addNavigationBarButtons() {
        
        //right item
        let uploadBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPhotoTapped(sender:)))
        self.navigationItem.rightBarButtonItem = uploadBtn
        
        //left item
        let logoutBtn = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout(sender:)))
        self.navigationItem.leftBarButtonItem = logoutBtn
    }
    
    func clearNavigationButtons() {
    
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = nil
    }
    
    func addPhotoTapped(sender:Any) {
    
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func logout(sender:Any) {
    
        let alert = UIAlertController(title: NSLocalizedString("Logout", comment: ""), message: NSLocalizedString("Do you want to Logout ?", comment: ""), preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default) { (action) in
            
            Flickr.shared.logout()
            
            self.collectionView.isHidden = true
            self.loginButton.isHidden = false
            self.dataArray.removeAll()
            self.collectionView.reloadData()
            
            self.clearNavigationButtons()
        }
        alert.addAction(yesAction)
        
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
        alert.addAction(noAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.activityIndicator.startAnimating()
            
            Flickr.shared.uploadImage(image: image) { (error) in
                
                DispatchQueue.main.async {
                    
                    self.activityIndicator.stopAnimating()
                    
                    if let error = error {
                        let alert = Util.configureAlert(withTitle: "Error", message: error.localizedDescription)
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        
                        let alert = Util.configureAlert(withTitle: "Success", message: "Upload successful")
                        self.present(alert, animated: true, completion: nil)
                        
                        self.currentPage = 1//back to page 1
                        self.loadUserPhotos()
                    }
                }//end dispatch
            }
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCellIdentifier", for: indexPath) as! PhotoCell
        
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
            self.loadUserPhotos()
        }
    }
}
