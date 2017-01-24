//
//  Flickr.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 23/1/17.
//
//

import UIKit

let apiKey = "c3c004846488012f97e4e6ef1a37527b"
let apiSecret = "64f017f1d7603b3f"
let kErrorDomainFlickr = "FlickrError"

class Flickr: NSObject {
    
    static let shared = Flickr()//singleton
    var loginResultDict:[String:String] = [:]
    
    func getPublicPhotoFeed(success: @escaping ([FlickrItem]) -> Void,
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
    
    //https://www.flickr.com/services/api/auth.oauth.html
    func login() {
        
        let nonce = Util.random9DigitString()//TODO
        let timestamp = Int(Date().timeIntervalSince1970)
        let urlSceme = "jackyflickr"

        //Getting a Request Token
        let signatureBaseString:String = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&oauth_callback%3D\(urlSceme)%253A%252F%252F%26oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_version%3D1.0"
        
        let signatureHMACSHA1 = Util.getHmacSHA1(key: "\(apiSecret)&", input: signatureBaseString)
        
        let urlString:String = "https://www.flickr.com/services/oauth/request_token?oauth_nonce=\(nonce)&oauth_timestamp=\(timestamp)&oauth_consumer_key=\(apiKey)&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_signature=\(signatureHMACSHA1)&oauth_callback=\(urlSceme)://"
        
        if let url = URL(string: urlString) {
        
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                guard let data = data else { return }
                
                if let resultString = String(data: data, encoding:.utf8) {
                
                    let resultArray = resultString.characters.split{$0 == "&"}.map(String.init)
                    
                    //convert array to dictionary
                    
                    for result in resultArray {
                        let splitArray = result.characters.split{$0 == "="}.map(String.init)
                        
                        if (splitArray[0] == "oauth_problem") {
                            //don't proceed if there's a problem
                            print("oauth_problem: \(splitArray[1])")
                            return
                        }
                        
                        self.loginResultDict[splitArray[0]] = splitArray[1]
                    }
                    
                    //Getting the User Authorization
                    if let oauthToken = self.loginResultDict["oauth_token"] {
                    
                        if let url = URL(string: "https://www.flickr.com/services/oauth/authorize?oauth_token=\(oauthToken)") {
                            
                            //request for access token
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    }
                }
                
            }).resume()
        }
    }
    
    func requestAcessToken(dict:[String:String]) {
    
        let nonce = Util.random9DigitString()//TODO
        let timestamp = Int(Date().timeIntervalSince1970)
        
        guard let oauthToken = dict["oauth_token"], let oauthVerifier = dict["oauth_verifier"], let oauthTokenSecret = loginResultDict["oauth_token_secret"] else {
            return
        }
        
        //Getting a Request Token
        let signatureBaseString:String = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Faccess_token&oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_token%3D\(oauthToken)%26oauth_verifier%3D\(oauthVerifier)%26oauth_version%3D1.0"
        
        let tokenSecret = "\(apiSecret)&\(oauthTokenSecret)"
        let signatureHMACSHA1 = Util.getHmacSHA1(key: tokenSecret, input: signatureBaseString)
        
        let urlString:String = "https://www.flickr.com/services/oauth/access_token?oauth_nonce=\(nonce)&oauth_timestamp=\(timestamp)&oauth_verifier=\(oauthVerifier)&oauth_consumer_key=\(apiKey)&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=\(oauthToken)&oauth_signature=\(signatureHMACSHA1)"
        
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
                guard let data = data else { return }
                
                if let resultString = String(data: data, encoding:.utf8) {
                    
                    let resultArray = resultString.characters.split{$0 == "&"}.map(String.init)

                    //sample result:
                    /*
                     resultArray: ["fullname=Jacky%20Tjoa", "oauth_token=72157679427529266-c3ae7c17509e7492", "oauth_token_secret=80ed0ab87eb54fea", "user_nsid=126131380%40N05", "username=jacky_coolheart"]
                     */
                    
                    for result in resultArray {
                        
                        let splitArray = result.characters.split{$0 == "="}.map(String.init)
                        
                        if (splitArray[0] == "oauth_problem") {
                            //don't proceed if there's a problem
                            print("oauth_problem: \(splitArray[1])")
                            return
                        }
                    }
                    
                    //For demo purpose and for simplicity, store access token to User Defaults
                    UserDefaults.standard.set(oauthToken, forKey: "access_token")
                    
                    print("login success !")
                    print("resultArray: \(resultArray)")
                }
                
            }).resume()
        }
    }
    
    func testLogin(accessToken:String) {
        
        let nonce = Util.random9DigitString()//TODO
        let timestamp = Int(Date().timeIntervalSince1970)
        
        //Test login
        let signatureBaseString:String = "GET&https%3A%2F%2Fapi.flickr.com%2Fservices%2Frest&format%3Djson%26method%3Dflickr.test.login%26nojsoncallback%3D1%26oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_token%3D\(accessToken)%26oauth_version%3D1.0"
        
        let tokenSecret = "\(apiSecret)&"
        let signatureHMACSHA1 = Util.getHmacSHA1(key: tokenSecret, input: signatureBaseString)
        
        let urlString:String = "https://api.flickr.com/services/rest?nojsoncallback=1&oauth_nonce=\(nonce)&format=json&oauth_consumer_key=\(apiKey)&&oauth_timestamp=\(timestamp)&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=\(accessToken)&oauth_signature=\(signatureHMACSHA1)&method=flickr.test.login"
        
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                guard let data = data else { return }
                
                if let resultString = String(data: data, encoding:.utf8) {
                
                    print("resultString: \(resultString)")
                }
                
                do {
                    
                    guard let resultDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject]
                        else {
                            return
                    }
                    
                    print("resultDict: \(resultDict)")
                    
                } catch {
                    print(error)
                }
                
            }).resume()
        }
    }
}
