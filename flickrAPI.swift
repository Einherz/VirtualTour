//
//  flickrAPI.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 9/17/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "22470b79775c7cf4e6880c8c26289f78"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
var LIMIT_NUMBER = "51"
let NO_JSON_CALLBACK = "1"
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

class flickrAPI{
    
    func findImageByLocation(lat:Double, long:Double, callback:(jsonData:NSArray) -> ()){
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "accuracy": String(arc4random_uniform(15)),
            "bbox": createBoundingBoxString(lat, long:long),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "per_page": LIMIT_NUMBER,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { // Handle error...
                let alert = UIAlertController(title: "Problem", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                    return
                }))
            }

            do {
                let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            callback(jsonData: photosArray)
                        }
                }
            } catch let error as NSError{
                print("error : \(error.localizedDescription)")
            }
        }
        task.resume()

    }
    
    func createBoundingBoxString(lat:Double, long:Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(long - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(lat - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(long + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(lat + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }

        return (!urlVars.isEmpty ? "?" : "") +  urlVars.joinWithSeparator("&")
    }
    
}

