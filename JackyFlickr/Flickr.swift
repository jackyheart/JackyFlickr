//
//  Flickr.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 23/1/17.
//
//

import UIKit

let apiKey = "c3c004846488012f97e4e6ef1a37527b"
let kErrorDomainFlickr = "FlickrError"

class Flickr: NSObject {
    
    static func getPublicPhotoFeed(success: @escaping ([FlickrItem]) -> Void,
                         failure:@escaping (NSError) -> Void) {
    
        let urlString = "https://api.flickr.com/services/feeds/photos_public.gne?api_key=\(apiKey)&format=json&nojsoncallback=1"//&lang=en-us
        
        guard let url = URL(string: urlString) else {
            
            let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Invalid url"])
            failure(error)
            return
        }
    
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            guard let data = data else {
                let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Unparasable data from Flickr"])
                failure(error)
                return
            }
            
            do {
            
                guard let resultDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject]
                else {
                    let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Unparasable data from Flickr"])
                    failure(error)
                    return
                }
                
                guard let feedItems = resultDict["items"] as? [[String:AnyObject]] else {
                    let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Unparasable data from Flickr"])
                    failure(error)
                    return
                }
                
                var flickrItems:[FlickrItem] = []
                
                for item in feedItems {
                    
                    let flickrItem = FlickrItem()
                    if let media = item["media"] as? [String:AnyObject] {
                        if let urlString = media["m"] as? String {
                            flickrItem.urlString = urlString
                        }
                    }
                    
                    flickrItems.append(flickrItem)
                }
                
                success(flickrItems)
                
            } catch {
                let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Unparasable data from Flickr"])
                failure(error)
            }
            
        }).resume()
    }
}
