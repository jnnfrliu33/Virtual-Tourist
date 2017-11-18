//
//  AlertViewController.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 18/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import Foundation
import UIKit

// MARK: - AlertViewController

class AlertViewController {
    
    class func showAlert(controller: UIViewController, message: String) {
        let alert = UIAlertController(title: "Something's wrong!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        performUIUpdatesOnMain {
            controller.present(alert, animated: true, completion: nil)
        }
    }
}
