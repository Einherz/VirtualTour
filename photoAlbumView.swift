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
    var blockOperations: [NSBlockOperation] = []
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
                        self.sharedContext.performBlockAndWait({ () -> Void in
                            let imageDB = ImageEntity(dictionary: photos as! [String : AnyObject], context: self.sharedContext)
                            imageDB.imageToPin = self.imageToPin
                            
                        })
                        }
                        self.sharedContext.performBlockAndWait({ () -> Void in
                         dbConnector.sharedInstance().saveContext() })

                          dispatch_async(dispatch_get_main_queue(), {
                        self.newPicBtn.enabled = true
                            })
        
//                       self.sharedContext.performBlockAndWait({ () -> Void in
//                        
//                        })
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
            self.sharedContext.performBlockAndWait({ () -> Void in
            let ImageData = self.fetchedResultsController.objectAtIndexPath(imgPos) as! ImageEntity
            dbConnector.Caches.imageCache.clearImage(ImageData.image)
            self.sharedContext.deleteObject(ImageData)
            })
        }
        dbConnector.sharedInstance().saveContext()

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
        let fetchRequest = NSFetchRequest(entityName: "ImageEntity")
        fetchRequest.includesPropertyValues = false
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        for myImg in self.fetchedResultsController.fetchedObjects!
        {
            self.sharedContext.performBlockAndWait({ () -> Void in
            let img = myImg as! ImageEntity
            self.sharedContext.deleteObject(img)
            dbConnector.Caches.imageCache.clearImage(img.image)
            dbConnector.sharedInstance().saveContext()
            })
        }
        self.gridImage.reloadData()
//        do{
//            try self.sharedContext.save( )
//        } catch let error as NSError {
//            print(error.localizedDescription)
//        }
        
//        do{
//            try self.sharedContext.executeRequest(deleteRequest)
//        } catch let error as NSError {
//            print(error.localizedDescriptio  n)
//            }
           // dbConnector.sharedInstance().saveContext()

        
        print("after delete data : \(fetchedResultsController.fetchedObjects?.count)")
        
        //Load new Images//
        let flickr = flickrAPI()
        flickr.findImageByLocation(currentAnnotation.latitude, long: currentAnnotation.longitude) { (jsonData) -> () in
            if(jsonData.count > 0){
                self.gridImage.hidden = false
                for photos in jsonData {
                    self.sharedContext.performBlockAndWait({ () -> Void in
                        let imageDB = ImageEntity(dictionary: photos as! [String : AnyObject], context: self.sharedContext)
                        imageDB.imageToPin = self.imageToPin
                        
                    })
                }
                self.sharedContext.performBlockAndWait({ () -> Void in
                    dbConnector.sharedInstance().saveContext() })
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.newPicBtn.enabled = true
                })
            } else { //in case no images at that pin
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

        if let ImageData = fetchedResultsController.objectAtIndexPath(indexPath) as? ImageEntity
        {
            let imageLoader = imageAsync()
            imageLoader.loadImage(ImageData) { (imageCallBack,imgNo) -> () in
            dispatch_async(dispatch_get_main_queue(), {
            cell.backgroundView = UIImageView(image: imageCallBack)
            })
        }
        }
                   //}
       
       // }
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
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        weak var collection = self.gridImage
        switch type {
        case .Insert:
            print("insert")
            self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                if let this = self {
                    this.gridImage.insertSections(NSIndexSet(index: sectionIndex))
                }}))
            
//            self.blockoperation.addExecutionBlock({ () -> Void in
//                collection?.insertSections(NSIndexSet(index: sectionIndex))
//            })
            
        case .Delete:
            print("delete")
            self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                if let this = self {
                    this.gridImage.deleteSections(NSIndexSet(index: sectionIndex))
                }}))
            
//            self.blockoperation.addExecutionBlock({ () -> Void in
//                collection?.deleteSections(NSIndexSet(index: sectionIndex))
//            })
           
        case .Update:
            print("update")
            self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                if let this = self {
                    this.gridImage.reloadSections(NSIndexSet(index: sectionIndex))
                }}))
            
//            self.blockoperation.addExecutionBlock({ () -> Void in
//                collection?.reloadSections(NSIndexSet(index: sectionIndex))
//            })
            
        case .Move:
            print("move")
            
        }
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        weak var collection = self.gridImage

        
        switch type {
        case .Insert:
                print("insert")
               // print(collection!.numberOfItemsInSection((newIndexPath?.section)!))
                if(collection!.numberOfSections() > 0){
                    if(collection!.numberOfItemsInSection((newIndexPath?.section)!) == 0){
                        shouldReloadCollectionView = true
                    } else {
                        self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                            if let this = self {
                                this.gridImage.insertItemsAtIndexPaths([newIndexPath!])
                            }}))
                        
//                        self.blockoperation.addExecutionBlock({ () -> Void in
//                            self.gridImage.insertItemsAtIndexPaths([newIndexPath!])
//                        })
                    }
                } else {
                   shouldReloadCollectionView = true
                }
            
        case .Delete:
            print("delete")
            //print(self.gridImage.numberOfItemsInSection((indexPath?.section)!))
            if(collection!.numberOfItemsInSection((indexPath?.section)!) == 1){
                shouldReloadCollectionView = true
            } else {
                self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                    if let this = self {
                        this.gridImage.deleteItemsAtIndexPaths([indexPath!])
                    }}))
                
//                self.blockoperation.addExecutionBlock({ () -> Void in
//                    self.gridImage.deleteItemsAtIndexPaths([indexPath!])
//                })
            }
            
        case .Update:
            print("update")
            self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                if let this = self {
                    this.gridImage.reloadItemsAtIndexPaths([indexPath!])
                }}))
            
//            self.blockoperation.addExecutionBlock({ () -> Void in
//                self.gridImage.reloadItemsAtIndexPaths([indexPath!])
//            })

        case .Move:
            print("move")
            self.blockOperations.append(NSBlockOperation(block: {[weak self] in
                if let this = self {
                    this.gridImage.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                }}))
            
//            self.blockoperation.addExecutionBlock({ () -> Void in
//                self.gridImage.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
//            })
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    
        if(shouldReloadCollectionView){
            print("do reload Data")
            self.gridImage.reloadData()
        } else {
            //print("counting : \(self.countImg)")
            //if(self.countImg == 50){
                //self.countImg = 0
                self.gridImage.performBatchUpdates({ () -> Void in
                    for operation:NSBlockOperation in self.blockOperations{
                        operation.start()
                    }
                    //self.blockoperation.start()
                    print("done")
                    }, completion: { (finished) -> Void in
                        self.blockOperations.removeAll(keepCapacity: false)
                })
            //}
           
        }
    }
    
    deinit{
        for operation:NSBlockOperation in blockOperations{
            operation.cancel()
        }
        blockOperations.removeAll(keepCapacity: false)
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