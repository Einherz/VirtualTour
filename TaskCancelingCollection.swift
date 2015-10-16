//
//  TaskCancelingCollection.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 10/1/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation

import UIKit

class TaskCancelingCollection : UICollectionViewCell {
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}