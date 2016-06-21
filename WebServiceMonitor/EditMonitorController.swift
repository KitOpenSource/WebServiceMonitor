//
//  EditMonitorController.swift
//  WebServiceMonitor
//
//  Created by Kit on 20/6/2016.
//  Copyright © 2016年 Maximity Tech. All rights reserved.
//

import UIKit

class EditMonitorController: UITableViewController {
    var monitor:[String:AnyObject]?
    var indexPath:NSIndexPath?
    @IBAction func stepperAction(sender: AnyObject) {
        if let stepper = sender as? UIStepper {
            switch stepper.tag {
            case 0:
                intervalTextField.text = String(Int(stepper.value))
            case 1:
                thresholdTextField.text = String(Int(stepper.value))
            case 2:
                timeoutTextField.text = String(Int(stepper.value))
            default:
                break
            }
        }
        
    }
    @IBOutlet weak var timeoutTextField: UITextField!
    @IBOutlet weak var thresholdTextField: UITextField!
    @IBOutlet weak var intervalTextField: UITextField!
    @IBOutlet weak var pathTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var intervalStepper: UIStepper!
    @IBOutlet weak var thresholdStepper: UIStepper!
    @IBOutlet weak var timeoutStepper: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if let monitor = self.monitor {
            if let host:String = monitor["host"] as? String {
                hostTextField.text = host
            }
            if let port:String = monitor["port"] as? String {
                portTextField.text = port
            }
            if let path:String = monitor["path"] as? String {
                pathTextField.text = path
            }
            if let interval:Int = monitor["interval"] as? Int {
                intervalTextField.text = String(interval)
                intervalStepper.value = Double(interval)
            } else {
                intervalTextField.text = "5"
                intervalStepper.value = 5
            }
            if let threshold:Int = monitor["threshold"] as? Int {
                thresholdTextField.text = String(threshold)
                thresholdStepper.value = Double(threshold)
            } else {
                thresholdTextField.text = "2"
                intervalStepper.value = 2
            }
            if let timeout:Int = monitor["timeout"] as? Int {
                timeoutTextField.text = String(timeout)
                timeoutStepper.value = Double(timeout)
            } else {
                timeoutTextField.text = "3"
                timeoutStepper.value = 3
            }
        }
        
        
        
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let host = hostTextField.text {
            monitor!["host"] = host
        }
        if let port = portTextField.text {
            monitor!["port"] = port
        }
        if let path = pathTextField.text {
            monitor!["path"] = path
        }
        if let interval = intervalTextField.text {
            monitor!["interval"] = Int(interval)
        }
        if let threshold = thresholdTextField.text {
            monitor!["threshold"] = Int(threshold)
        }
        if let timeout = timeoutTextField.text {
            monitor!["timeout"] = Int(timeout)
        }
        
        
        let monitorListCtrl = self.navigationController?.viewControllers.first as? MonitorListController
        monitorListCtrl?.updateMonitor(monitor, indexPath: indexPath)
    }
    
        
    
    
}
