//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 09/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import Foundation

// MARK: FlickrClient (Convenience Resource Methods)

extension FlickrClient {
    
    // MARK: Properties
    
    static let methodParameters: [String:AnyObject] = [
        FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod as AnyObject,
        FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey as AnyObject,
        FlickrParameterKeys.BoundingBox: bboxString() as AnyObject,
        FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch as AnyObject,
        FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL as AnyObject,
        FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat as AnyObject,
        FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback as AnyObject,
        FlickrParameterKeys.PhotosPerPage: FlickrParameterValues.PhotosPerPage as AnyObject
    ]
    
    // MARK: GET Convenience Methods
    
    func getPhotos(_ methodParameters: [String:AnyObject] = methodParameters, completionHandlerForGetPhotos: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        let _ = taskForGETMethod(methodParameters) { (photosDictionary, error) in
            
            if let error = error {
                completionHandlerForGetPhotos(nil, error)
            } else {
                if let totalPages = photosDictionary?[FlickrResponseKeys.Pages] as? Int, totalPages > 0 {
                    
                    // Pick a random page
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    
                    self.getPhotos(methodParameters, withPageNumber: randomPage, completionHandlerForGetPhotos: completionHandlerForGetPhotos)
                    
                } else {
                    completionHandlerForGetPhotos(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getPhotos"]))
                }
            }
        }
    }
    
    func getPhotos(_ methodParameters: [String:AnyObject] = methodParameters, withPageNumber: Int, completionHandlerForGetPhotos: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        // Add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        let _ = taskForGETMethod(methodParameters) { (photosDictionary, error) in
            
            if let error = error {
                completionHandlerForGetPhotos(nil, error)
            } else {
                if let photosArray = photosDictionary?[FlickrResponseKeys.Photo] as? [[String: AnyObject]], photosArray.count > 0 {
                    
                    var photoURLArray = [URL]()
                    
                    for photo in photosArray {
                        
                        if let imageURLString = photo[FlickrResponseKeys.MediumURL] as? String {
                            photoURLArray.append(URL(string: imageURLString)!)
                        }
                    }
                    
                    completionHandlerForGetPhotos(photoURLArray as AnyObject, nil)
                }
            }
        }
    }
    
    // MARK: Helpers
    
    static func bboxString() -> String {
        
        // Ensure bbox is bounded by minimum and maximums
        if let latitude = PhotoAlbumViewController.coordinate?.latitude, let longitude = PhotoAlbumViewController.coordinate?.longitude {
            let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
}
