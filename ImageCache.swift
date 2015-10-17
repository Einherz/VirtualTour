//
//  File.swift
//  FavoriteActors
//
//  Created by Jason on 1/31/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

//Borrow Caching API :)

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    func clearImage(path: String){
        let imgName = pathForIdentifier(path)
        inMemoryCache.removeObjectForKey(imgName)
        do{
            try NSFileManager.defaultManager().removeItemAtPath(imgName)
        } catch {
        }
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            do{
               try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch {
            }
            return
        } else {
            
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path)
        
        // And in documents directory
        let data = UIImageJPEGRepresentation(image!, 1.0)
            //UIImagePNGRepresentation(image!)
        print("image save : \(path)")
        do{
            try data!.writeToFile(path, options: NSDataWritingOptions.DataWritingAtomic)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        data!.writeToFile(path, atomically: true)
       
        }
    }
    
    // MARK: - Helper
    
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL:NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)[0] as NSURL
        
        //has to cut string out from coredata
        //but in coredate we save the full image
        let imageName = identifier.characters.split{$0 == "/"}.map(String.init)
        
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(imageName[imageName.count-1])
        
        return fullURL.path!
    }
}