//
//  ViewController.swift
//  forShaker
//
//  Created by Roman Spirichkin on 28/01/16.
//  Copyright © 2016 rs. All rights reserved.
//

import UIKit

class RSMacImage: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var RSImageView: UIImageView!
    @IBOutlet weak var RSCollectionView: UICollectionView!
    var imgRowAndID : (Int, Int!) = (-1,nil) // nil means ID of Main Big Image
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.RSCollectionView.delegate = self
        self.RSCollectionView.dataSource = self
        
        // set Image
        if let ID = self.imgRowAndID.1 {
        self.RSImageView.image = messages[self.imgRowAndID.0].arrayImages[ID]
        } else {
            self.RSImageView.image = messages[self.imgRowAndID.0].image
        }
    }
    
    
    // collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages[self.imgRowAndID.0].arrayImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RSCollectionCell", forIndexPath: indexPath)
        // set images
        let img = UIImageView(frame: cell.bounds)
        img.image = messages[self.imgRowAndID.0].arrayImages[indexPath.row]
        cell.addSubview(img)
        cell.layer.cornerRadius = (self.view.bounds.height/4 - 12)/4
        cell.layer.borderWidth = 0
        cell.clipsToBounds = true
        return cell
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((self.view.bounds.height/4 - 12)/2, (self.view.bounds.height/4 - 12)/2)
    }
}


// MARK: Structure
class Message {
    let id, time : Int
    let urlArrayImages : [String]
    let urlImage, name : String
    var arrayImages : [UIImage] = []
    var image : UIImage! = nil
    init(id : Int, time : Int, urlArrayImages : [String], urlImage:  String, name: String) {
        self.id  = id; self.time = time; self.name = name;
        self.urlArrayImages = urlArrayImages; self.urlImage = urlImage;
    }
}
var messages : [Message] = []

let RSHeight : CGFloat = 240


// MARK: EXTENSIONS
extension UIImage {
    static func fromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
        var uncompressedPNGData: NSData      { return UIImagePNGRepresentation(self)!        }
        var highestQualityJPEGNSData: NSData { return UIImageJPEGRepresentation(self, 1.0)!  }
        var highQualityJPEGNSData: NSData    { return UIImageJPEGRepresentation(self, 0.75)! }
        var mediumQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.5)!  }
        var lowQualityJPEGNSData: NSData     { return UIImageJPEGRepresentation(self, 0.25)! }
        var b:NSData   { return UIImageJPEGRepresentation(self, 0.0)!  }
}
