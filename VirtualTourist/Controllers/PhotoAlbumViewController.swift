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
    var updatedIndexPaths: [IndexPath]!
    
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
            // Get photos from Flickr if selected pin has no persisted photos
            getPhotos()
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
    
    func getPhotos() {
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
                print (self.imageURLArray)
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
        
        // Delete current set of photos
        for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
            self.sharedContext.delete(photo)
        }
        
        // Get new set of photos
        getPhotos()
    }
    
    func deletedSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexPaths {
            photosToDelete.append(self.fetchedResultsController.object(at: indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            self.sharedContext.delete(photo)
        }
        
        selectedIndexPaths = [IndexPath]()
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
        
        if self.fetchedResultsController.fetchedObjects?.count != 0 {
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
        if self.fetchedResultsController.fetchedObjects?.count != 0 {
            let image = self.fetchedResultsController.object(at: indexPath) as! Photo
            let imageData = image.imageData
            
            // Set the image from the imageData and stop the activity indicator animation
            cell.imageView.image = UIImage(data: imageData as Data)
            cell.activityIndicator.stopAnimating()
            
        } else {
            
            // Download image data if selected pin has no persisted photos
            let imageURLString = imageURLArray[(indexPath as NSIndexPath).row]
            let imageData = try? Data(contentsOf: URL(string: imageURLString)!)
            
            // Create Photo object
            let photoObject = Photo(imageData: imageData! as NSData, context: self.sharedContext)
            photoObject.pin = PhotoAlbumViewController.selectedPin
            
            // Set the image from the imageData and stop the activity indicator animation
            cell.imageView.image = UIImage(data: imageData!)
            cell.activityIndicator.stopAnimating()
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
        self.deletedIndexPaths = [IndexPath]()
        self.updatedIndexPaths = [IndexPath]()

    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .delete:
            self.deletedIndexPaths.append(indexPath!)
        case .update:
            self.updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Perform batch updates
        self.collectionView.performBatchUpdates({ () -> Void in

            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }

            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }

        }, completion: nil)
    }
}
