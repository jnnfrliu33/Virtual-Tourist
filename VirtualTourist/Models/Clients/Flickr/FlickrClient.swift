//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 09/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import Foundation

// MARK: - FlickrClient: NSObject

class FlickrClient: NSObject {
    
    // MARK: Properties
    
    var photoURLArray = [URL]()
    
    // MARK: GET Method
    
    func taskForGETMethod(_ methodParameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError((error?.localizedDescription)!)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* Parse data */
            self.convertDataWithCompletionHandler(data) { (result, error) in
                
                if let error = error {
                    completionHandlerForGET(nil, error)
                } else {
                
                    /* GUARD: Did Flickr return an error (stat != ok)? */
                    guard let stat = result?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                        sendError("Flickr API returned an error. See error code and message in \(String(describing: result))")
                        return
                    }
                    
                    /* GUARD: Are the "photos" and "photo" keys in our result? */
                    guard let photosDictionary = result?[FlickrResponseKeys.Photos] as? [String : AnyObject] else {
                        sendError("Cannot find keys '\(FlickrResponseKeys.Photos)' in \(String(describing: result))")
                        return
                    }
                
                    completionHandlerForGET(photosDictionary as AnyObject, nil)
                }
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: Helpers
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
