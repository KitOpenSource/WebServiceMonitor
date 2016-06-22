//
//  MonitorListController.swift
//  WebServiceMonitor
//
//  Created by Kit on 20/6/2016.
//  Copyright © 2016年 Maximity Tech. All rights reserved.
//

import UIKit

class MonitorListController: UITableViewController {

    var monitorList:[[String:AnyObject]] = []
    var timerList:[String:NSTimer] = [:]
    var statusList:[Bool] = []
    var thresholdList:[String:Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).monitorListCtrl = self
        
        //monitorList = [["host":"mood.ibeacon-macau.com", "port":"80", "path":"/api/checkAlive", "interval":3, "threshold":2, "timeout":5, "enable":true]]
        monitorList = NSUserDefaults.standardUserDefaults().objectForKey("monitorList") as? Array ?? []
        statusList = [Bool](count:monitorList.count, repeatedValue: false)
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MonitorListController.addAction(_:)))
        self.navigationItem.rightBarButtonItems = [addButton]
        
        startMonitoring()
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveMonitor()
    }
    
    func saveMonitor() {
        NSUserDefaults.standardUserDefaults().setObject(monitorList, forKey: "monitorList")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func addAction(sender:UIBarButtonItem) {
        let monitor = ["host":"", "port":"", "path":"", "interval":3, "threshold":2, "timeout":5, "enable":false]
        monitorList.append(monitor)
        statusList.append(false)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: monitorList.count - 1, inSection: 0)], withRowAnimation: .Bottom)
    }
    
    func enableAction(sender:UISwitch) {
        print(sender.on)
        if let indexPath = tableView.indexPathForCell(sender.superview?.superview as! UITableViewCell) {
            monitorList[indexPath.row]["enable"] = sender.on
            
            if sender.on {
                startSingleMonitoring(monitorList[indexPath.row])
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            } else {
                statusList[indexPath.row] = false
                stopSingleMonitoring(monitorList[indexPath.row])
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
        
        
    }
    
    func updateThreshold(monitor:[String:AnyObject], success:Bool) {
        var url:String
        if let host:String = monitor["host"] as? String {
            if host == "" {
                return
            }
            url = host
            
            if let port:String = monitor["port"] as? String {
                url = host + ":" + port
            }
            
            if let path:String = monitor["path"] as? String {
                url += path
            }
            
            if let current:Int = thresholdList[url] {
                if success {
                    thresholdList[url] = current + 1
                    if thresholdList[url] >= monitor["threshold"] as? Int {
                        thresholdList[url] = monitor["threshold"] as? Int
                        if let index = getMonitorIndex(monitor) {
                            statusList[index] = true
                            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
                        }
                        
                    }
                } else {
                    thresholdList[url] = current - 1
                    if thresholdList[url] <= 0 {
                        thresholdList[url] = 0
                        if let index = getMonitorIndex(monitor) {
                            statusList[index] = false
                            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
                        }
                    }
                }
                
            } else {
                if success {
                    thresholdList[url] = 1
                    if thresholdList[url] >= monitor["threshold"] as? Int {
                        thresholdList[url] = monitor["threshold"] as? Int
                        if let index = getMonitorIndex(monitor) {
                            statusList[index] = true
                            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
                        }
                    }
                } else {
                    thresholdList[url] = 0
                    if thresholdList[url] <= 0 {
                        thresholdList[url] = 0
                        if let index = getMonitorIndex(monitor) {
                            
                            statusList[index] = false
                            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
                        }
                    }
                }
            }
        }
    }
    
    func getMonitorIndex(monitor:[String:AnyObject]) -> Int? {
        let index = monitorList.indexOf { (item: [String : AnyObject]) -> Bool in
            return (monitor["host"] as! String) == (item["host"] as! String) && (monitor["port"] as! String) == (item["port"] as! String) && (monitor["path"] as! String) == (item["path"] as! String)
                
            
        }
        
        return index
        
    }
    
    func monitoringTask(timer:NSTimer) {
        print(NSDate())
        if let monitor:[String:AnyObject] = timer.userInfo as? Dictionary {
            if monitor["enable"] as! Bool == false {
                return
            }
            let manager = AFHTTPSessionManager()
            var url:String
            if let host:String = monitor["host"] as? String {
                if host == "" {
                    return
                }
                url = host
                
                if let port:String = monitor["port"] as? String {
                    if host == "" {
                        url = host + ":80"
                    }
                    url = host + ":" + port
                }
                
                if let path:String = monitor["path"] as? String {
                    url += path
                }
                if let timeout:Int = monitor["timeout"] as? Int {
                    manager.requestSerializer.timeoutInterval = Double(timeout)
                } else {
                    manager.requestSerializer.timeoutInterval = 60
                }
                
                url = "http://" + url
                url = url.stringByReplacingOccurrencesOfString(" ", withString: "", options: .LiteralSearch, range: nil)
                url = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
                manager.POST(String(url), parameters: nil, progress: nil, success: { (task:NSURLSessionDataTask, object:AnyObject?) in
                    self.updateThreshold(monitor, success: true)
                    self.updateSingleMonitoring(monitor)
                    }, failure: { (task:NSURLSessionDataTask?, error:NSError) in
                    self.updateThreshold(monitor, success: false)
                    self.updateSingleMonitoring(monitor)
                })
            }
            
        }
        
    }

    
    func updateMonitor(monitor:[String:AnyObject]!, indexPath:NSIndexPath!) {
        monitorList[indexPath.row] = monitor
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        stopSingleMonitoring(monitor)
        startSingleMonitoring(monitor)
        
    }
    
    func startMonitoring() {
        stopMonitoring()
        print("start monitoring")
        for monitor in monitorList {
            
                startSingleMonitoring(monitor)
            
            
        }
    }
    
    func stopMonitoring() {
        print("stop monitoring")
        if !timerList.isEmpty {
            for timer in timerList.values {
                timer.invalidate()
            }
            timerList.removeAll()
        }
    }
    
    func startSingleMonitoring(monitor:[String:AnyObject]) {
        if monitor["enable"] as! Bool == false {
            return
        }
        var url:String
        if let host:String = monitor["host"] as? String {
            if host == "" {
                return
            }
            url = host
            
            if let port:String = monitor["port"] as? String {
                url = host + ":" + port
            }
            
            if let path:String = monitor["path"] as? String {
                url += path
            }
            
            var timer:NSTimer
            if let interval:Double = monitor["interval"]?.doubleValue {
                timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(MonitorListController.monitoringTask(_:)), userInfo: monitor, repeats: false)
            } else {
                timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(MonitorListController.monitoringTask(_:)), userInfo: monitor, repeats: false)
            }
            
            timerList[url] = timer
        }
    }
    
    func updateSingleMonitoring(monitor:[String:AnyObject]) {
        var url:String
        if let host:String = monitor["host"] as? String {
            if host == "" {
                return
            }
            url = host
            
            if let port:String = monitor["port"] as? String {
                url = host + ":" + port
            }
            
            if let path:String = monitor["path"] as? String {
                url += path
            }
            
            var timer:NSTimer
            if let interval:Double = monitor["interval"]?.doubleValue {
                timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(MonitorListController.monitoringTask(_:)), userInfo: monitor, repeats: false)
            } else {
                timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(MonitorListController.monitoringTask(_:)), userInfo: monitor, repeats: false)
            }
            
            timerList.updateValue(timer, forKey: url)
        }
    }
    
    func stopSingleMonitoring(monitor:[String:AnyObject]) {
        var url:String
        if let host:String = monitor["host"] as? String {
            url = host
            
            if let port:String = monitor["port"] as? String {
                url = host + ":" + port
            }
            
            if let path:String = monitor["path"] as? String {
                url += path
            }
            
            timerList[url]?.invalidate()
            timerList.removeValueForKey(url)
        }

    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return monitorList.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            monitorList.removeAtIndex(indexPath.row)
            statusList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellId = "monitorcell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! MonitorTableViewCell
        
        let monitor = monitorList[indexPath.row]
        if let host:String = monitor["host"] as? String {
            cell.hostLabel.text = host
            
            if let port:String = monitor["port"] as? String {
                cell.hostLabel.text = host + ":" + port
            }
        }
        if let path:String = monitor["path"] as? String {
            cell.pathLabel.text = path
        }
        
        if let enable:Bool = monitor["enable"] as? Bool {
            cell.enableSwitch.setOn(enable, animated: true)
            
            cell.backgroundColor = UIColor.whiteColor()
            if enable {
                if let status:Bool = statusList[indexPath.row] {
                    if status {
                        cell.backgroundColor = UIColor.greenColor()
                    } else {
                        cell.backgroundColor = UIColor.redColor()
                    }
                }
            }
            

        }
        
        cell.enableSwitch.addTarget(self, action: #selector(MonitorListController.enableAction(_:)), forControlEvents: .ValueChanged)
        
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editMonitor" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let destCrtl = segue.destinationViewController as! EditMonitorController
                if let monitor:[String:AnyObject] = monitorList[indexPath.row] {
                    destCrtl.monitor = monitor
                    destCrtl.indexPath = indexPath
                }
            }
        }
    }
}
