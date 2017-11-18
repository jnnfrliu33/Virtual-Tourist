//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 14/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//
//

import Foundation
import CoreData

// MARK: - Photo: NSManagedObject

public class Photo: NSManagedObject {
    
    convenience init(imageData: NSData, context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.imageData = imageData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
