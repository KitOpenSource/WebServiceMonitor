//
//  AppDelegate.swift
//  WebServiceMonitor
//
//  Created by Kit on 10/6/2016.
//  Copyright © 2016年 Maximity Tech. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var monitorListCtrl: MonitorListController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound],
                                                  categories: nil)
        application.registerUserNotificationSettings(settings)
        
        return true
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if let monitorList:[[String:AnyObject]] = NSUserDefaults.standardUserDefaults().objectForKey("monitorList") as? Array {
            for monitor in monitorList {
                backgroundMonitoring(monitor)
            }
        }
        completionHandler(.NewData)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        monitorListCtrl?.saveMonitor()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        monitorListCtrl?.stopMonitoring()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        monitorListCtrl?.startMonitoring()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    func backgroundMonitoring(monitor:[String:AnyObject]) {
        print(NSDate())
        if let monitor:[String:AnyObject] = monitor {
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
                print(url)
                manager.POST("http://mood.ibeacon-macau.com:80/api/checkAlive", parameters: nil, progress: nil, success: { (task:NSURLSessionDataTask, object:AnyObject?) in
                    if UIApplication.sharedApplication().applicationState == .Background {
                        let localNotification = UILocalNotification()
                        localNotification.fireDate = NSDate(timeIntervalSinceNow: 0)
                        localNotification.timeZone = NSTimeZone.defaultTimeZone()
                        localNotification.alertBody = "Success: " + url
                        localNotification.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                    }
                    
                    }, failure: { (task:NSURLSessionDataTask?, error:NSError) in
                        if UIApplication.sharedApplication().applicationState == .Background {
                            let localNotification = UILocalNotification()
                            localNotification.fireDate = NSDate(timeIntervalSinceNow: 0)
                            localNotification.timeZone = NSTimeZone.defaultTimeZone()
                            localNotification.alertBody = "Warning: " + url
                            localNotification.soundName = UILocalNotificationDefaultSoundName
                            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                        }
                })
            }
            
        }
    }
    
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ibeacon-macau.WebServiceMonitor" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("WebServiceMonitor", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

