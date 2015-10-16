//
//  pinStruct.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 9/17/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(PinEntity)

class PinEntity : NSManagedObject{
    
struct pinStruct  {
    static let id = "id"
    static let Lat = "latitude"
    static let Long = "longitude"
    static let Date = "date"
    }
    
    @NSManaged var id:NSNumber?
    @NSManaged var latitude:NSNumber?
    @NSManaged var longitude:NSNumber?
    @NSManaged var date:String?
    @NSManaged var pinToImage: NSSet?
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject],context:NSManagedObjectContext){
        
        let entity =  NSEntityDescription.entityForName("PinEntity", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary[pinStruct.id] as? NSNumber
        latitude = dictionary[pinStruct.Lat] as? NSNumber
        longitude = dictionary[pinStruct.Long] as? NSNumber
        date = dictionary[pinStruct.Date] as? String
    }

}
