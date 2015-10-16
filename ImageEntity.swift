//
//  imageStruct.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 9/17/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(ImageEntity)

class ImageEntity:NSManagedObject{
    
struct imageStruct {
    static let Title = "title"
    static let Image = "url_m"
    }
    
    @NSManaged var title:String!
    @NSManaged var image:String!
    @NSManaged var imageToPin: PinEntity?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(dictionary: [String: AnyObject],context:NSManagedObjectContext){
        
        let entity =  NSEntityDescription.entityForName("ImageEntity", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[imageStruct.Title] as! String
        image = dictionary[imageStruct.Image] as! String
    }
    
    var cacheImg: UIImage? {
        get {
            return dbConnector.Caches.imageCache.imageWithIdentifier(image)
        }
        set(cache) {
            dbConnector.Caches.imageCache.storeImage(cache, withIdentifier: image)
        }
    }
    
}