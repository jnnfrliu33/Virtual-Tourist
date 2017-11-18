//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 14/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData
    @NSManaged public var pin: Pin?

}
