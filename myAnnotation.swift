//
//  myAnnotation.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 10/1/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import MapKit

class myAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var status: String
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, status: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.status = status
    }
}
