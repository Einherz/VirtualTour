//
//  imageController.swift
//  virtualtour
//
//  Created by Amorn Apichattanakul on 9/17/15.
//  Copyright © 2015 amorn. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData


class photoAlbumView: UIViewController,MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var currentAnnotation = CLLocationCoordinate2D()
    var titleArray = [String]()
    var photoArray = [String]()
    var dataTemp = [ImageEntity]()
    var imageToPin:PinEntity!
    var delFlag = false
    var sectionInfo:Int = 0
    var countImg = 0
    var indexArray = [NSIndexPath]()
    var blockoperation:NSBlockOperation = NSBlockOperation()
    //var blockOperations: [NSBlockOperation] = []
    var shouldReloadCollectionView:Bool = false

    
    @IBOutlet weak var newPicBtn: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var gridImage: UICollectionView!
    @IBOutlet weak var removePicBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = currentAnnotation
        
        let viewRegion = MKCoordinateRegionMakeWithDistance(currentAnnotation, 20000, 20000)
        let adjustRegion = self.mapView.regionThatFits(viewRegion)
        self.mapView.setRegion(adjustRegion, animated: true)

        self.mapView.addAnnotation(annotation)
        self.mapView.centerCoordinate = currentAnnotation
        
        self.gridImage.allowsMultipleSelection = true
       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        do{
            try self.fetchedResultsController.performFetch()
        } catch {
            print("error")
        }
        
        self.fetchedResultsController.delegate = self
        
        if let count = self.fetchedResultsController.fetchedObjects?.count{
            if (count > 0){// If data exist
                self.newPicBtn.enabled = true
//                for myImage in self.fetchedResultsController.fetchedObjects!
//                {
//                    let imageDB = myImage as! ImageEntity
//                }
            } else { // If no data exist
                
                let flickr = flickrAPI()
                flickr.findImageByLocation(currentAnnotation.latitude, long: currentAnnotation.longitude) { (jsonData) -> () in
                    if(jsonData.count > 0){
                        self.gridImage.hidden = false
                    for photos in jsonData {
                        let imageDB = ImageEntity(dictionary: photos as! [String : AnyObject], context: self.sharedContext)
                        imageDB.imageToPin = self.imageToPin
                        dispatch_async(dispatch_get_main_queue(), {
                            //self.gridImage.reloadData()
                            self.newPicBtn.enabled = true
                        })
                        
                        //dbConnector.sharedInstance().saveContext()
                        }
                    } else { //in case no images at that pin
                        dispatch_async(dispatch_get_main_queue(), {
                            self.gridImage.hidden = true
                        })
                    }
                }
            }
            
            self.gridImage.delegate = self
            self.gridImage.dataSource = self
        }
    }

    //Mark : MapviewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView?.animatesDrop = true
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    @IBAction func backAction(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func removeImages(sender: UIButton) {
        print("remove image")
        for imgPos in indexArray{
            let ImageData = fetchedResultsController.objectAtIndexPath(imgPos) as! ImageEntity
            dbConnector.Caches.imageCache.clearImage(ImageData.image)
            self.sharedContext.deleteObject(ImageData)
        }
        indexArray.removeAll()
        
        //Hide remove image
        self.removePicBtn.hidden = true
        self.removePicBtn.enabled = false
        self.newPicBtn.hidden = false
        self.newPicBtn.enabled = true
    }
    @IBAction func getNewImages(sender: UIButton) {
        //remove all coredata in this position
        print("load images")
        
        for myImg in fetchedResultsController.fetchedObjects!
        {
            let img = myImg as! ImageEntity
            dbConnector.Caches.imageCache.clearImage(img.image)
            self.sharedContext.deleteObject(img)
        }
        dbConnector.sharedInstance().saveContext()

        print("after delete data : \(fetchedResultsController.fetchedObjects?.count)")
        
        //Load new Images//
        let flickr = flickrAPI()
        flickr.findImageByLocation(currentAnnotation.latitude, long: currentAnnotation.longitude) { (jsonData) -> () in
            if(jsonData.count > 0){
                self.gridImage.hidden = false
                for photos in jsonData {
                    let imageDB = ImageEntity(dictionary: photos as! [String : AnyObject], context: self.sharedContext)
                    imageDB.imageToPin = self.imageToPin
                    dbConnector.sharedInstance().saveContext()
                }
                print("after loading data : \(self.fetchedResultsController.fetchedObjects?.count)")
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.gridImage.reloadData()
//                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.gridImage.hidden = true
                })
            }
        }
        
    }
    
    
   // Mark Collection view
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collectionSectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        self.sectionInfo = collectionSectionInfo.numberOfObjects
        self.gridImage.collectionViewLayout.invalidateLayout()
        return collectionSectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "myCell"
        
        let cell = self.gridImage.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! TaskCancelingCollection
        
        cell.backgroundView = UIImageView(image: UIImage(named: "human"))
        
        if(cell.selected){
           cell.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        } else {
           cell.contentView.backgroundColor = UIColor.clearColor()
        }
        
        let ImageData = fetchedResultsController.objectAtIndexPath(indexPath) as! ImageEntity
        
        let imageLoader = imageAsync()
        imageLoader.loadImage(ImageData) { (imageCallBack,imgNo) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                 cell.backgroundView = UIImageView(image: imageCallBack)
            })
        }
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
       
        if (self.removePicBtn.hidden){
            self.newPicBtn.enabled = false
            self.newPicBtn.hidden = true
            self.removePicBtn.hidden = false
            self.removePicBtn.enabled = true
        }
        let thisCell = collectionView.cellForItemAtIndexPath(indexPath)
    
        thisCell?.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        thisCell?.backgroundColor = UIColor.whiteColor()
        indexArray.append(indexPath)
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let thisCell = collectionView.cellForItemAtIndexPath(indexPath)
        thisCell?.contentView.backgroundColor = UIColor.clearColor()
        var position = 0;
        for item in indexArray{
            if(item == indexPath){
                indexArray.removeAtIndex(position)
            }
            position++;
        }
    }


    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("start operation")
        shouldReloadCollectionView = false
        self.blockoperation = NSBlockOperation.init()
       // blockOperations.removeAll(keepCapacity: false)
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        weak var collection = self.gridImage
        switch type {
        case .Insert:
                print("insert")
                print(self.gridImage.numberOfSections())
                print(self.gridImage.numberOfItemsInSection((newIndexPath?.section)!))
                if(self.gridImage.numberOfSections() > 0){
                    if(self.gridImage.numberOfItemsInSection((newIndexPath?.section)!) == 0){
                        shouldReloadCollectionView = true
                    } else {
                        self.blockoperation.addExecutionBlock({ () -> Void in
                            self.gridImage.insertItemsAtIndexPaths([newIndexPath!])
                        })
                       }
                } else {
                   shouldReloadCollectionView = true
                }
            
        case .Delete:
            print("delete")
            print(self.gridImage.numberOfItemsInSection((indexPath?.section)!))
            if(self.gridImage.numberOfItemsInSection((indexPath?.section)!) == 1){
                shouldReloadCollectionView = true
            } else {
                self.blockoperation.addExecutionBlock({ () -> Void in
                    self.gridImage.deleteItemsAtIndexPaths([indexPath!])
                })
            }
            
            
        case .Update:
            print("update")
            self.blockoperation.addExecutionBlock({ () -> Void in
                self.gridImage.reloadItemsAtIndexPaths([indexPath!])
            })

        case .Move:
            print("move")
            self.blockoperation.addExecutionBlock({ () -> Void in
                self.gridImage.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            })
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if(shouldReloadCollectionView){
            print("do reload")
            self.gridImage.reloadData()
        } else {
             print("do batch")
            self.gridImage.performBatchUpdates({ () -> Void in
                self.blockoperation.start()
                }, completion: nil)
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "ImageEntity")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "imageToPin == %@", self.imageToPin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    var sharedContext: NSManagedObjectContext {
        return dbConnector.sharedInstance().managedObjectContext
    }
}