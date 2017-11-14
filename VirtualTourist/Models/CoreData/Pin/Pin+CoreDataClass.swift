//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 14/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

// MARK: - Pin: NSManagedObject, MKAnnotation

public class Pin: NSManagedObject, MKAnnotation {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    // Convert latitude and longitude into CLLocationCoordinate2D
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude as Double, longitude: self.longitude as Double)
    }
}
