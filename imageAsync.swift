//
//  imageAsync.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 10/1/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import UIKit

class imageAsync {
    
    func loadImage(imgObj: ImageEntity, onComplete: (imageCallBack:UIImage, imgNo:Int) -> ())
    {
        var tempImage = UIImage(named: "human")
        
          if imgObj.image == "" || imgObj.image == nil {
            onComplete(imageCallBack: tempImage!,imgNo: 0)
            //cell.backgroundView = UIImageView(image: tempImage) //No image from FlickrAPI or something went wrong
          } else if imgObj.cacheImg != nil {// use cache
            print("get image from cache)")
            tempImage = imgObj.cacheImg
            onComplete(imageCallBack: tempImage!,imgNo: 0)
          }
            
        else {
            
            let baseURL = NSURL(string: imgObj.image)
            let request = NSURLRequest(URL: baseURL!)
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithRequest(request) {data, response, error in
                if error != nil {
                    print("error downloading image : \(error!.localizedDescription)")
                    return
                } else {
                    if let imgData = data {
                        let imageData = UIImage(data: imgData)
                        let imageHolder = imgObj.cacheImg //Instantiate setter
                        imgObj.cacheImg = imageData
                        onComplete(imageCallBack: imageData!,imgNo: 1)
                    }
                }
            }
            task.resume()
        }
    }
}
