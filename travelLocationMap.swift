//
//  ViewController.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 9/10/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import UIKit
import MapKit
import CoreData

//Work progress
//Choose Image Collection to clear image and data // Working
//New Collection to wipe out core data and re-save again // Working

class travelLocationMap: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    
    @IBOutlet weak var bottomMapFrame: NSLayoutConstraint!
    @IBOutlet weak var topMapFrame: NSLayoutConstraint!
    var editFlag:Bool = false
    
    var position: PinEntity!
    var imgLocation:PinEntity!
    
    
    var annotations = [myAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        let press:UILongPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action: "addPin:")
        press.minimumPressDuration = 0.5;
        self.mapView.addGestureRecognizer(press)
        
        do{
          try fetchedResultsController.performFetch()
        } catch {
            print("error")
        }
        
        fetchedResultsController.delegate = self

        for myPin in fetchedResultsController.fetchedObjects!
        {
            let pin = myPin as! PinEntity
            
            let annotation = myAnnotation(coordinate: CLLocationCoordinate2D(latitude: pin.latitude as! Double, longitude: pin.longitude as! Double), title: "", subtitle: "", status: pin.date!)
            
            self.annotations.append(annotation)
        }
        
        self.mapView.addAnnotations(self.annotations)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func removeData(sender: UIBarButtonItem) {
        if(!self.editFlag){
            print("edit Mode")
            self.editBtn.enabled = false
            self.editBtn.title = "Done"
            self.view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: {
                self.topMapFrame.constant -= 30
                self.bottomMapFrame.constant += 30
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    self.editFlag = true
                    self.editBtn.enabled = true
            })
            
        } else {
            print("normal Mode")
            self.editBtn.enabled = false
            self.editBtn.title = "Edit"
            self.view.layoutIfNeeded()

            UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: {
                self.topMapFrame.constant += 30
                self.bottomMapFrame.constant -= 30
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                   self.editFlag = false
                    self.editBtn.enabled = true
            })

        }
        
    }
    
    func addPin(gestureRecognizer:UIGestureRecognizer) {
        if(gestureRecognizer.state == UIGestureRecognizerState.Began) {
            let point:CGPoint = gestureRecognizer.locationInView(self.mapView)
            let tapPoint:CLLocationCoordinate2D = self.mapView.convertPoint(point, toCoordinateFromView: self.view)
            
            //let annotation = MKPointAnnotation()
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateStyle = .LongStyle
            formatter.timeStyle = .MediumStyle
            let dateString = formatter.stringFromDate(date)
            
            do{
                try fetchedResultsController.performFetch()
            } catch {
                print("error")
            }
            
            let totalPin = fetchedResultsController.fetchedObjects!.count
            
           // annotation.
            let annotation = myAnnotation(coordinate: tapPoint, title: "", subtitle: "", status: dateString)
           // annotation.subtitle = dateString
           // annotation.coordinate = tapPoint
            self.annotations.append(annotation)
            
            self.mapView.addAnnotations(self.annotations)
            
            //Save pin to CoreData
            let pinData: [String:AnyObject] = [
                PinEntity.pinStruct.id : NSNumber(integer: (totalPin+1)),
                PinEntity.pinStruct.Lat : NSNumber(double: annotation.coordinate.latitude),
                PinEntity.pinStruct.Long : NSNumber(double: annotation.coordinate.longitude),
                PinEntity.pinStruct.Date : dateString ?? ""
            ]
            
            let pinDB = PinEntity(dictionary: pinData, context: sharedContext)
            dbConnector.sharedInstance().saveContext()
        }
    }
    
    
    //Mark : MapviewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView?.animatesDrop = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if let idPin = view.annotation as? myAnnotation{
            
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "date MATCHES %@", idPin.status)
        }
        
        do{
            try fetchedResultsController.performFetch()
        } catch {
            print("error")
        }
        
        if(self.editFlag){
            for myPin in fetchedResultsController.fetchedObjects!
            {
                print("delete")
                let pin = myPin as! PinEntity
                self.imgLocation = fetchedResultsController.fetchedObjects?.first as! PinEntity
                
                fetchedResultsControllerImage.fetchRequest.predicate = NSPredicate(format: "imageToPin == %@", self.imgLocation)
                do{
                    try self.fetchedResultsControllerImage.performFetch()
                } catch {
                    print("error")
                }
                
                for myImage in self.fetchedResultsControllerImage.fetchedObjects!
                {
                  let imageDB = myImage as! ImageEntity
                  dbConnector.Caches.imageCache.clearImage(imageDB.image)
                }
                sharedContext.deleteObject(pin)
                
                dbConnector.sharedInstance().saveContext()
            }
            
            self.mapView.removeAnnotation(view.annotation!)
            self.annotations.removeAll()
            
        } else {
            //Go to FlickrAPI
            mapView.deselectAnnotation(view.annotation, animated: true)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewControllerWithIdentifier("imageView") as! photoAlbumView
            let imageToPin = fetchedResultsController.fetchedObjects?.first as! PinEntity
            
            
            viewController.currentAnnotation = (view.annotation?.coordinate)!
            viewController.imageToPin = imageToPin
            self.presentViewController(viewController, animated: true, completion: nil)
        }
       
    }
    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        <#code#>
//    }
//    
//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        <#code#>
//    }
//    
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        <#code#>
//    }
//    
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        <#code#>
//    }

lazy var fetchedResultsController: NSFetchedResultsController = {
    
    let fetchRequest = NSFetchRequest(entityName: "PinEntity")
    
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
        managedObjectContext: self.sharedContext,
        sectionNameKeyPath: nil,
        cacheName: nil)
    
    return fetchedResultsController
    
    }()
    
    lazy var fetchedResultsControllerImage: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "ImageEntity")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        //fetchRequest.predicate = NSPredicate(format: "imageToPin == %@", self.imgLocation)
        
        let fetchedResultsControllerImage = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsControllerImage
        
        }()
    
    var sharedContext: NSManagedObjectContext {
        return dbConnector.sharedInstance().managedObjectContext
    }

}

