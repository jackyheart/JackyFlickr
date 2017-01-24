//
//  LoginViewController.swift
//  JackyFlickr
//
//  Created by Jacky on 24/1/17.
//
//

import UIKit

//https://www.flickr.com/services/api/auth.spec.html

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //observe for access token
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccessTokenNotification(notification:)), name: NSNotification.Name(rawValue: "AccessTokenNotification"), object: nil)
        
        if let accessToken = UserDefaults.standard.object(forKey: "access_token") as? String {
        
            Flickr.shared.testLogin(accessToken: accessToken)
        }
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
    
        Flickr.shared.login()
    }
    
    //MARK: - NSNotificationCenter
    
    func handleAccessTokenNotification(notification:Notification) {
        
        guard let tokenDict = notification.object as? [String:String] else {
            return
        }
        
        Flickr.shared.requestAcessToken(dict: tokenDict)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
