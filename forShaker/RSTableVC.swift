//
//  ViewController.swift
//  forShaker
//
//  Created by Roman Spirichkin on 28/01/16.
//  Copyright © 2016 rs. All rights reserved.
//

import UIKit
import Starscream
import Alamofire
import AFNetworking
import SwiftyJSON


class RSTableVC: UITableViewController, WebSocketDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var RSActivity: UIActivityIndicatorView!
    let socket = WebSocket(url: NSURL(string: "ws://54.154.96.23:8082")!)
    var imgRowAndID : (Int, Int!) = (-1,nil) // nil means ID of Main Big Image
    var storedOffsets = [Int: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        socket.delegate = self
        socket.connect()
        RSActivity.center = CGPoint(x: self.view.bounds.width/2, y: (self.view.bounds.height-60)/2)
        self.view.addSubview(RSActivity)
        RSActivity.startAnimating()
    }
    
    
    // MARK : WebSocket
    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
    }
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("got some data: \(data.length)")
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("got some text: \(text)")
        if let dataFromString = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
            let url = json["url"].string
            dispatch_async(dispatch_get_main_queue()) {
                self.HTTPRequest(url!)
            }
        }
    }
    
    
    // MARK: HTTP Request
    func HTTPRequest(url: String) {
        Alamofire.request(.GET, url).responseJSON { response in
                if let dummyData = response.data {
                    let dummyJSON = JSON(data: dummyData)
                    for (_, subJSON) in dummyJSON {
                        let newMessages = Message(id: subJSON["id"].intValue, time: subJSON["time"].intValue, urlArrayImages: (subJSON["images"].array?.filter({ $0.string != nil }).map({ $0.string! }))!, urlImage: subJSON["url"].stringValue, name: subJSON["name"].stringValue)
                        messages.append(newMessages)
                    }
                } else { print("No-No-No ;(") }
            // sort & reload
            messages.sortInPlace({$0.time < $1.time})
            self.tableView.reloadData()
            self.RSActivity.removeFromSuperview()
            // 2download
            dispatch_async(dispatch_get_main_queue()) {
                self.downloadingImages()
            }
        }
    }
    
    
    // MARK: downloading Image
    func downloadingImages() {
        for msg in messages {
            //image
            Alamofire.request(.GET, msg.urlImage).responseJSON { response in
                if let imgData = response.data {
                    msg.image = UIImage(data: imgData)
                    self.tableView.reloadData()
                }
            }
            //arayImages
            for url in msg.urlArrayImages {
            Alamofire.request(.GET, url).responseJSON { response in
                if let imgData = response.data {
                    msg.arrayImages.append(UIImage(data: imgData)!)
                    self.tableView.reloadData()
                }
                }
            }
        }
    }
    
    
    // MARK: TableView
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return RSHeight
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("RSTableCell") as! RSTableCell
        if let img = messages[indexPath.row].image  { cell.RSImage.image = img }
        cell.RSImage.layer.cornerRadius = (RSHeight-40)/4 //forRound
        cell.RSImage.layer.borderWidth = 0
        cell.RSImage.clipsToBounds = true
        cell.RSNameLabel.text = messages[indexPath.row].name
        cell.RSnLfbel.text = "\(messages[indexPath.row].urlArrayImages.count)"
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let tableViewCell = cell as? RSTableCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let tableViewCell = cell as? RSTableCell else { return }
        
        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            tableView.cellForRowAtIndexPath(indexPath)!.selectionStyle = UITableViewCellSelectionStyle.None
            self.imgRowAndID = (indexPath.row, nil)
            self.performSegueWithIdentifier("RSSegueMacImage", sender: self)
    }
    
    override func prepareForSegue(segue:(UIStoryboardSegue!), sender:AnyObject!)
    {
        if segue.identifier == "RSSegueMacImage" {
            (segue.destinationViewController as! RSMacImage).imgRowAndID = self.imgRowAndID
        }
    }

    // collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages[collectionView.tag].arrayImages.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RSCollectionCell", forIndexPath: indexPath)
        let img = UIImageView(frame: cell.bounds)
        img.image = UIImage(data: messages[collectionView.tag].arrayImages[indexPath.row].lowQualityJPEGNSData)
        cell.addSubview(img)
        cell.layer.cornerRadius = (RSHeight - 100 - 24 - 12)/4  //forRound
        cell.layer.borderWidth = 0
        cell.clipsToBounds = true
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.imgRowAndID = (collectionView.tag, indexPath.row)
        self.performSegueWithIdentifier("RSSegueMacImage", sender: self)
    }
}



class RSTableCell : UITableViewCell {
    
    @IBOutlet weak var RSImage: UIImageView!
    @IBOutlet weak var RSNameLabel: UILabel!
    @IBOutlet weak var RSnLfbel: UILabel!
    @IBOutlet weak var RSCollection: UICollectionView!
    
        // collectionView
        func setCollectionViewDataSourceDelegate<D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>(dataSourceDelegate: D, forRow row: Int) {
            RSCollection.delegate = dataSourceDelegate
            RSCollection.dataSource = dataSourceDelegate
            RSCollection.tag = row
            RSCollection.setContentOffset(RSCollection.contentOffset, animated:false) // Stops collection view if it was scrolling.
            RSCollection.reloadData()
        }
        var collectionViewOffset: CGFloat {
            set { RSCollection.contentOffset.x = newValue  }
            get { return RSCollection.contentOffset.x }
        }
}
