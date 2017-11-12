//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 09/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import UIKit
import MapKit

// MARK: - MapViewController: UIViewController

class MapViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: Properties
    
    var pinDropGesture: UILongPressGestureRecognizer?
    
    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up pin drop gesture
        self.pinDropGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.dropPin))
        self.mapView.addGestureRecognizer(self.pinDropGesture!)
    }
    
    // MARK: Functions
    
    @objc func dropPin(sender: UIGestureRecognizer) {
        
        // Create coordinate point object
        let point = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)

        // Only allow pins to be dropped once
        if sender.state == .began {

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
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        // Save the coordinate in PhotoAlbumViewController to be used
        PhotoAlbumViewController.coordinate = view.annotation?.coordinate
        
        // Get the photos for the coordinate
        FlickrClient.sharedInstance().getPhotos() { (photoURLArray, error) in
            if let error = error {
                print (error)
            } else {
                FlickrClient.sharedInstance().photoURLArray = photoURLArray as! [URL]
            }
        }
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
}


