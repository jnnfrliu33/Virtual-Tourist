//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 09/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - PhotoAlbumViewController: UIViewController

class PhotoAlbumViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refreshCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    static var selectedPin: Pin? = nil
    
    // Shared context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStack.sharedInstance().context
    }()
    
    // Fetched Results Controller for persisting photos
    lazy var fetchedResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        
        // Create fetch request and filter photos by selected pin
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", PhotoAlbumViewController.selectedPin!)
        
        // Create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Zoom in the map on the location
        centerMapOnLocation((PhotoAlbumViewController.selectedPin?.coordinate)!)
        
        // Set the annotation on the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = (PhotoAlbumViewController.selectedPin?.coordinate)!
        self.mapView.addAnnotation(annotation)
        
        // Check if the selected pin contains persisted photos
        if PhotoAlbumViewController.selectedPin?.photos?.count != 0 {
            
            // Fetch persisted photos
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                print ("Unable to fetch photos!")
            }
            
        } else {
            
            // Download and save photos from Flickr if selected pin has no persisted photos
            FlickrClient.sharedInstance().getPhotos() { (photosArray, error) in
                if let error = error {
                    print (error)
                } else {
                    if let photosArray = photosArray as? [[String:AnyObject]] {
                        
                        // Loop through photosArray and create Photo object for each photo dictionary
                        for photo in photosArray {
                            
                            if let imageURLString = photo[FlickrClient.FlickrResponseKeys.MediumURL] as? String {
                                let imageData = try? Data(contentsOf: URL(string: imageURLString)!)
                                let photoObject = Photo(imageData: imageData! as NSData, context: self.sharedContext)
                                photoObject.pin = PhotoAlbumViewController.selectedPin
                            }
                        }
                    }
                    
                    // Fetch newly added photos
                    do {
                        try self.fetchedResultsController.performFetch()
                    } catch {
                        print ("Unable to fetch photos!")
                    }
                }
            }
        }
    }
    
    // MARK: Helpers
    
    // Define zoom radius of location
    let regionRadius: CLLocationDistance = 500
    func centerMapOnLocation (_ coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: - PhotoAlbumViewController: MKMapViewDelegate

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

// MARK: PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let image = self.fetchedResultsController.object(at: indexPath) as! Photo
        let imageData = image.imageData
        
        // Set the image from the imageData and stop the activity indicator animation
        cell.imageView.image = UIImage(data: imageData as Data)
        cell.activityIndicator.stopAnimating()
        
        return cell
    }
}

// MARK: - PhotoAlbumViewController: NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // collectionView.beginUpdates()
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//
//        let set = IndexSet(integer: sectionIndex)
//
//        switch (type) {
//        case .insert:
//            collectionView.insertSections(set)
//        case .delete:
//            collectionView.deleteSections(set)
//        default:
//            break
//        }
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//
//        switch (type) {
//        case .insert:
//            collectionView.insertItems(at: [newIndexPath!])
//        case .delete:
//            collectionView.deleteItems(at: [indexPath!])
//        case .update:
//            collectionView.reloadItems(at: [indexPath!])
//        case .move:
//            collectionView.deleteItems(at: [indexPath!])
//            collectionView.insertItems(at: [newIndexPath!])
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // collectionView.endUpdates()
//    }
}
