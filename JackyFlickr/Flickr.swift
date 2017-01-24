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
                let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Empty data from Flickr"])
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
    func login(failure: @escaping (NSError) -> Void) {
        
        let nonce = Util.getNonce()
        let timestamp = Int(Date().timeIntervalSince1970)
        let urlSceme = "jackyflickr"

        //Getting a Request Token
        let signatureBaseString = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&oauth_callback%3D\(urlSceme)%253A%252F%252F%26oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_version%3D1.0"
        
        let signatureHMACSHA1 = Util.getHmacSHA1(key: "\(apiSecret)&", input: signatureBaseString)
        
        let urlString = "https://www.flickr.com/services/oauth/request_token?oauth_nonce=\(nonce)&oauth_timestamp=\(timestamp)&oauth_consumer_key=\(apiKey)&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_signature=\(signatureHMACSHA1)&oauth_callback=\(urlSceme)://"
        
        if let url = URL(string: urlString) {
        
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                guard let data = data else { return }
                
                if let resultString = String(data: data, encoding:.utf8) {
                
                    let resultArray = resultString.characters.split{$0 == "&"}.map(String.init)
                    
                    //convert array to dictionary
                    var errorEncountered = false
                    
                    for result in resultArray {
                        let splitArray = result.characters.split{$0 == "="}.map(String.init)
                        
                        if (splitArray[0] == "oauth_problem") {
                            //don't proceed if there's a problem
                            print("oauth_problem: \(splitArray[1])")
                            errorEncountered = true
                            break
                        }
                        
                        self.loginResultDict[splitArray[0]] = splitArray[1]
                    }
                    
                    if errorEncountered {
                    
                        let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Login failed. Please try again."])
                        failure(error)
                        return
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
    
    func requestAcessToken(tokenDict:[String:String], success: @escaping ([String:String]?) -> Void, failure: @escaping (NSError) -> Void) {
    
        let nonce = Util.getNonce()
        let timestamp = Int(Date().timeIntervalSince1970)
        
        guard let oauthToken = tokenDict["oauth_token"], let oauthVerifier = tokenDict["oauth_verifier"], let oauthTokenSecret = self.loginResultDict["oauth_token_secret"] else {
            return
        }
        
        //Getting a Request Token
        let signatureBaseString = "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Faccess_token&oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_token%3D\(oauthToken)%26oauth_verifier%3D\(oauthVerifier)%26oauth_version%3D1.0"
        
        let tokenSecret = "\(apiSecret)&\(oauthTokenSecret)"
        let signatureHMACSHA1 = Util.getHmacSHA1(key: tokenSecret, input: signatureBaseString)
        
        let urlString = "https://www.flickr.com/services/oauth/access_token?oauth_nonce=\(nonce)&oauth_timestamp=\(timestamp)&oauth_verifier=\(oauthVerifier)&oauth_consumer_key=\(apiKey)&&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=\(oauthToken)&oauth_signature=\(signatureHMACSHA1)"
        
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
                guard let data = data else {
                    let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Response data is empty"])
                    failure(error)
                    return
                }
                
                if let resultString = String(data: data, encoding:.utf8) {
                    
                    let resultArray = resultString.characters.split{$0 == "&"}.map(String.init)

                    //sample result:
                    /*
                     resultArray: ["fullname=Jacky%20Tjoa", "oauth_token=72157679427529266-c3ae7c17509e7492", "oauth_token_secret=80ed0ab87eb54fea", "user_nsid=126131380%40N05", "username=jacky_coolheart"]
                     */
                    
                    var userDict:[String:String] = [:]
                    var errorEncountered = false
                    
                    for result in resultArray {
                        
                        let splitArray = result.characters.split{$0 == "="}.map(String.init)
                        
                        if (splitArray[0] == "oauth_problem") {
                            //don't proceed if there's a problem
                            print("oauth_problem: \(splitArray[1])")
                            errorEncountered = true
                            break
                        }
                        
                        userDict[splitArray[0]] = splitArray[1]
                    }
                    
                    if(errorEncountered) {
                        let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Login failed. Please try again."])
                        failure(error)
                        return
                    }

                    if let oauthToken = userDict["oauth_token"], let oauthTokenSecret = userDict["oauth_token_secret"], let userID = userDict["user_nsid"], let username = userDict["username"], let fullname = userDict["fullname"] {
                    
                        LoggedInUser.shared.oauthToken = oauthToken
                        LoggedInUser.shared.oauthTokenSecret = oauthTokenSecret
                        LoggedInUser.shared.userID = userID
                        LoggedInUser.shared.username = username
                        LoggedInUser.shared.fullname = fullname
                    }
                    
                    print("login success !")
                    print("resultArray: \(resultArray)")
                    
                    success(userDict)
                }
                
            }).resume()
        }
    }
    
    func retrieveUserPhotos(complete:@escaping ([FlickrItem]) -> Void) {
    
        let nonce = Util.getNonce()
        let timestamp = Int(Date().timeIntervalSince1970)
        let userID = LoggedInUser.shared.userID
        let oauthToken = LoggedInUser.shared.oauthToken

        let page = 1 //TODO
    
        let urlString = "https://flickr.com/services/rest/?method=flickr.people.getPhotos&api_key=\(apiKey)&user_id=\(userID)&page=\(page)&per_page=20&format=json&nojsoncallback=1&oauth_nonce=\(nonce)&oauth_consumer_key=\(apiKey)&oauth_timestamp=\(timestamp)&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_token=\(oauthToken)"
        
        if let url = URL(string: urlString) {
        
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                guard let data = data else {
                    print("data is nil")
                    return
                }

                do {
                    
                    if let resultDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject] {
                    
                        print("resultDict: \(resultDict)")
                        
                        //user feeds
                        var userFeeds:[FlickrItem] = []
                        
                        if let photos = resultDict["photos"] as? [String:Any] {
                        
                            if let photoArray = photos["photo"] as? [[String:Any]] {
                                
                                for photoItem in photoArray {
                                
                                    if let server = photoItem["server"] as? String, let imageID = photoItem["id"] as? String, let secret = photoItem["secret"] as? String {
                                    
                                        let urlPath = self.constructFlickrImageURLPath(server: server, imageID: imageID, secret: secret)
                                        
                                        let flickrItem = FlickrItem()
                                        flickrItem.urlString = urlPath
                                        
                                        userFeeds.append(flickrItem)
                                    }
                                }//end for
                            }
                        }
                        
                        complete(userFeeds)
                    }
                    
                }
                catch {
                    print(error)
                }
                
            }).resume()
        }
    }
    
    private func constructFlickrImageURLPath(server:String, imageID:String, secret:String) -> String {
        return "https://farm2.staticflickr.com/\(server)/\(imageID)_\(secret).jpg"
    }
    
    //http://www.kaleidosblog.com/how-to-upload-images-using-swift-2-send-multipart-post-request
    func uploadImage(image:UIImage, completion: @escaping (NSError?) -> Void) {
        
        guard let url = URL(string: "https://up.flickr.com/services/upload/?") else {
            
            let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Error Uploading Image. Please try again."])
            completion(error)
            return
        }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        //define the multipart request type
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let image_data = UIImageJPEGRepresentation(image,0.3)
        
        if(image_data == nil)
        {
            let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Can't convert image to data. Please try again."])
            completion(error)
            return
        }
        
        let nonce = Util.getNonce()
        let timestamp = Int(Date().timeIntervalSince1970)
        let oauthToken = LoggedInUser.shared.oauthToken
        let oauthTokenSecret = LoggedInUser.shared.oauthTokenSecret
        
        let signatureBaseString = "POST&https%3A%2F%2Fup.flickr.com%2Fservices%2Fupload%2F&oauth_consumer_key%3D\(apiKey)%26oauth_nonce%3D\(nonce)%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D\(timestamp)%26oauth_token%3D\(oauthToken)%26oauth_version%3D1.0"
        
        let tokenSecret = "\(apiSecret)&\(oauthTokenSecret)"
        let signatureHMACSHA1 = Util.getHmacSHA1(key: tokenSecret, input: signatureBaseString)
        
        let params = ["oauth_consumer_key":"\(apiKey)",
                      "oauth_nonce":nonce,
                      "oauth_timestamp":"\(timestamp)",
                      "oauth_signature_method":"HMAC-SHA1",
                      "oauth_version":"1.0",
                      "oauth_token":oauthToken,
                      "oauth_signature":signatureHMACSHA1]
        
        let fname = "\(timestamp).jpg"
        let mimetype = "image/jpeg"
        
        //define the data post parameter
        let body = NSMutableData()
        
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"photo\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data!)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)

        request.httpBody = body as Data
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response, error == nil else {
                let error = NSError(domain: kErrorDomainFlickr, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Upload error"])
                completion(error)
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString)
            
            completion(nil)
        }
        
        task.resume()
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func logout() {
    
        LoggedInUser.shared.clear()
    }
}
