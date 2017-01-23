//
//  Flickr.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 23/1/17.
//
//

import UIKit

let apiKey = "c3c004846488012f97e4e6ef1a37527b"

class Flickr: NSObject {
    
    static func getPublicPhotos(success: @escaping (URLResponse?) -> Void,
                         failure:@escaping (Error?)->()) {
    
        //       let url :String = "https://api.flickr.com/services/feeds/photos_public.gne?api_key=c72a6c1c850b930522e96689d5c31e3c&format=json&nojsoncallback=1&lang=en-us"
        
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=\(apiKey)&per_page=20&format=json&nojsoncallback=1"
        
        //TODO
        guard let url = URL(string: urlString) else {
            return
        }
        
        //let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            guard let data = data else {
                return
            }
            
            do {
            
                guard let resultDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject], let stat = resultDict["stat"] as? String
                else {
                        return
                }
                
                if(stat == "ok") {
                    print("Results OK !")
                }
                else {
                    return
                }
                
                guard let photosDict = resultDict["photos"] as? [String:AnyObject], let photoArray = photosDict["photo"] as? [[String:AnyObject]] else {
                    return
                }
                
                for photo in photoArray {
                    
                    guard let photoID = photo["id"] as? String,
                        let farm = photo["farm"] as? Int ,
                        let server = photo["server"] as? String ,
                        let secret = photo["secret"] as? String else {
                            break
                    }

                    if let url =  getFlickrImageURL(photoID: photoID, farm: farm, server: server, secret: secret, size: "m") {
                        
                        
                        do {
                            let imageData = try Data(contentsOf: url as URL)
                        } catch {
                        
                        }
                    }
                }
                
            } catch {
            
            }
            
            
        }).resume()
        
        /*
        URLSession.shared.dataTask(with: url) { (data, response, error) in
         
            if error != nil {
                failure(error)
            }
            else {
                print("response: \(response)")
                success(response)
            }
        }
 */
    }
    
    static func getFlickrImageURL(photoID:String, farm:Int, server:String, secret:String, size:String) -> URL? {
    
        return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")
    }
}
