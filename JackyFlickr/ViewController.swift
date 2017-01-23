//
//  ViewController.swift
//  JackyFlickr
//
//  Created by Jacky Tjoa on 23/1/17.
//
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Flickr.getPublicPhotos(success: { (response) in
            
            print("res")
            
        }) { (error) in
            
            //TODO: show alert
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

