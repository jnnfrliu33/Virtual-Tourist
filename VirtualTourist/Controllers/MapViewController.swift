//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 09/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - MapViewController: UIViewController, NSFetchedResultsControllerDelegate

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: Properties
    
    var pinDropGesture: UILongPressGestureRecognizer?
    
    // Shared context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStack.sharedInstance().context
    }()
    
    // Fetched Results Controller for persisting pins
    lazy var fetchedResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        
        // Create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        
        // Create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()

    
    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up pin drop gesture
        self.pinDropGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.dropPin))
        self.mapView.addGestureRecognizer(self.pinDropGesture!)
        
        // Fetch persisted pins
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print ("Unable to fetch pins!")
        }
        
        // Add annotations from fetchedResultsController
        self.mapView.addAnnotations(self.fetchedResultsController.fetchedObjects as! [Pin] as [MKAnnotation])
    }
    
    // MARK: Functions
    
    @objc func dropPin(sender: UIGestureRecognizer) {
        
        // Create coordinate point object
        let point = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)

        // Only allow pins to be dropped once
        if sender.state == .began {
            
            // Create Pin object
            _ = Pin(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as Double, context: self.sharedContext)
            
            // Save context
            do {
                try CoreDataStack.sharedInstance().saveContext()
            } catch {
                print ("Unable to save context!")
            }

            // Set the annotation on the map
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
        }
    }
}

// MARK: - MapViewController: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        // Save the Pin in PhotoAlbumViewController to be used
        PhotoAlbumViewController.selectedPin = findPersistedPin((view.annotation?.coordinate)!)
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Helpers
    
    func findPersistedPin(_ coordinate: CLLocationCoordinate2D) -> Pin? {
        
        // Fetch newly added pins
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print ("Unable to fetch pins!")
        }
        
        let selectedPinLatitude = coordinate.latitude
        let selectedPinLongitude = coordinate.longitude
        
        // Loop through all fetched results to find the persisted pin
        for fetchedObject in self.fetchedResultsController.fetchedObjects! {
            let pin = fetchedObject as! Pin
            let pinLatitude = pin.latitude
            let pinLongitude = pin.longitude
            
            if selectedPinLatitude == pinLatitude && selectedPinLongitude == pinLongitude {
                return pin
            }
        }
        return nil
    }
}


