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
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Properties
    
    static var selectedPin: Pin? = nil
    var imageURLArray = [String]()
    
    // To keep track of selections, deletions and updates
    var selectedIndexPaths = [IndexPath]()
    var deletedIndexPaths: [IndexPath]!
    var insertedIndexPaths: [IndexPath]!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Zoom in the map on the location
        centerMapOnLocation((PhotoAlbumViewController.selectedPin?.coordinate)!)
        
        // Set the annotation on the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = (PhotoAlbumViewController.selectedPin?.coordinate)!
        self.mapView.addAnnotation(annotation)
        
        setCollectionFlowLayout()
        configureBottomButton()
        
        // Check if the selected pin contains persisted photos
        if PhotoAlbumViewController.selectedPin?.photos?.count != 0 {
            
            // Fetch persisted photos
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                print ("Unable to fetch photos!")
            }
            
        } else {
            // Get image URLs from Flickr if selected pin has no persisted photos
            getImageURLs()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Set collection flow layout when device orientation changes
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setCollectionFlowLayout()
        }
    }
    
    // MARK: Actions
    
    @IBAction func bottomButtonClicked(_ sender: Any) {
        if selectedIndexPaths.isEmpty {
            refreshPhotos()
        } else {
            deletedSelectedPhotos()
        }
    }
    
    // MARK: Helpers
    
    // Define zoom radius of location
    let regionRadius: CLLocationDistance = 500
    func centerMapOnLocation (_ coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func setCollectionFlowLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func getImageURLs() {
        FlickrClient.sharedInstance().getPhotos() { (imageURLArray, error) in
            if let error = error {
                AlertViewController.showAlert(controller: self, message: error.localizedDescription)
            } else {
                if let imageURLArray = imageURLArray as? [String] {
                    self.imageURLArray = imageURLArray
                }
                
                performUIUpdatesOnMain {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func configureBottomButton() {
        if selectedIndexPaths.isEmpty {
            bottomButton.title = "Refresh Photos"
        } else {
            bottomButton.title = "Delete Selected Photos"
        }
    }
    
    func refreshPhotos() {
        
        if let fetchedPhotos = self.fetchedResultsController.fetchedObjects, fetchedPhotos.count > 0 {
            
            // Delete current set of photos
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                self.sharedContext.delete(photo)
            }
        }
        
        // Save context
        do {
            try CoreDataStack.sharedInstance().saveContext()
        } catch {
            print ("Unable to save context!")
        }

        // Get new set of image URLs
        getImageURLs()
    }
    
    func deletedSelectedPhotos() {
        var photosToDelete = [Photo]()
            
        for indexPath in selectedIndexPaths {
            photosToDelete.append(self.fetchedResultsController.object(at: indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            self.sharedContext.delete(photo)
        }
        
        // Save context
        do {
            try CoreDataStack.sharedInstance().saveContext()
        } catch {
            print ("Unable to save context!")
        }
        
        // Reset selectedIndexPaths
        selectedIndexPaths.removeAll()
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
        
        if let fetchedPhotos = self.fetchedResultsController.fetchedObjects, fetchedPhotos.count > 0 {
            return (self.fetchedResultsController.sections?.count)!
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let fetchedPhotos = self.fetchedResultsController.fetchedObjects, fetchedPhotos.count > 0  {
            return self.fetchedResultsController.sections![section].numberOfObjects
        } else {
            return self.imageURLArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        // Set placeholder image and activity indicator
        cell.imageView.image = UIImage(named: "ImagePlaceholder")
        cell.activityIndicator.startAnimating()
        
        // Check if the selected pin contains persisted photos
        if let fetchedPhotos = self.fetchedResultsController.fetchedObjects, fetchedPhotos.count > 0 {
            let image = fetchedPhotos[(indexPath as NSIndexPath).item] as! Photo
            let imageData = image.imageData

            // Set the image from the imageData and stop the activity indicator animation
            cell.imageView.image = UIImage(data: imageData as Data)
            cell.activityIndicator.stopAnimating()

        } else {
            
            DispatchQueue.global(qos: .background).async {
                
                // Download image data if selected pin has no persisted photos
                let imageURLString = self.imageURLArray[(indexPath as NSIndexPath).row]

                if let imageData = try? Data(contentsOf: URL(string: imageURLString)!) {

                    self.sharedContext.performAndWait {
                        
                        // Create Photo object
                        let photoObject = Photo(imageData: imageData as NSData, context: self.sharedContext)
                        photoObject.pin = PhotoAlbumViewController.selectedPin
                        
                        // Save context
                        do {
                            try CoreDataStack.sharedInstance().saveContext()
                        } catch {
                            print ("Unable to save context!")
                        }
                        
                        // Fetch newly added photos
                        do {
                            try self.fetchedResultsController.performFetch()
                        } catch {
                            print ("Unable to fetch photos!")
                        }

                        // Set the image from the imageData and stop the activity indicator animation
                        cell.imageView.image = UIImage(data: photoObject.imageData as Data)
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCollectionViewCell
        
        // Toggle its presence in selectedIndexPaths whenever a cell is tapped
        if let index = selectedIndexPaths.index(of: indexPath) {
            cell.imageView.alpha = 1.0
            selectedIndexPaths.remove(at: index)
        } else {
            cell.imageView.alpha = 0.5
            selectedIndexPaths.append(indexPath)
        }
        
        configureBottomButton()
    }
}

// MARK: - PhotoAlbumViewController: NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Create fresh arrays when controller is about to make changes
        self.insertedIndexPaths = [IndexPath]()
        self.deletedIndexPaths = [IndexPath]()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            
        // Perform batch updates
        self.collectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}
