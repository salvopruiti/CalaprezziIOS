//
//  AppDelegate.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 09/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import DeviceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    var window: UIWindow?
    var alias: String = "Dispositivo Apple Sconosciuto";

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        getPreferences()
        enableNotifications(application)
        
        
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let aps = userInfo["aps"] as! [String: AnyObject]
        
        print("Notifica Remota Ricevuta")
        
        print(aps);
        
        // 1
        if aps["content-available"] as? Int == 1 {
            
            if let asin = aps["asin"] as? String, let notificationId = aps["notification_id"] as? String {
                
                ScrapingClass(notificationId, asin: asin).getAsin()
                
            }
            
            //let podcastStore = PodcastStore.sharedStore
            // Refresh Podcast
            // 2
            //podcastStore.refreshItems { didLoadNewItems in
                // 3
              //  completionHandler(didLoadNewItems ? .newData : .noData)
           // }
        } else  {
            // News
            // 4
            //_ = NewsItem.makeNewsItem(aps)
            //completionHandler(.newData)
        }
        
        print(userInfo["aps"]!)
    }
    
    func enableNotifications(_ application: UIApplication) {
        
        let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        application.registerForRemoteNotifications();
        
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Token Univoco: \(fcmToken)")
        
        sendTokenToServer(fcmToken)
        
        
    }
    
    func sendTokenToServer(_ fcmToken: String) {
        
        let url = URL(string: "https://app.calaprezzi.it/register")!
        
        var request = URLRequest(url: url)
        
        let device = Device()
        let model = device.model
        
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
        let buildNum = Bundle.main.infoDictionary!["CFBundleVersion"]!
        let app_version = "\(appVersion) (Build: \(buildNum))"
        let version = device.systemVersion
        let alias = self.alias
        
        var postData = [String:Any]()
        
        postData["alias"] = alias
        postData["client_type"] = 2
        postData["unique_id"] = fcmToken
        postData["device_manufacturer"] = "Apple"
        postData["device_model"] = device.description
        postData["os_version"] = version
        postData["device_product"] = model
        postData["version"] = app_version
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: postData, options: [])
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
        }
        task.resume()
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func getPreferences() {
        
        let preferences = UserDefaults.standard
        
        var alias: String? = preferences.string(forKey: "alias")
        var userCountry: String? = preferences.string(forKey: "user_country")
        
        if(alias == nil) {
            //todo apro storyboard per inserimento alias
            alias = alias ?? self.alias;
            userCountry = userCountry ?? "IT"
            
            preferences.set(alias, forKey: "alias")
            preferences.set(false, forKey: "configurated")
            preferences.set(userCountry, forKey: "user_country")
        

        }
        
        //preferences.set(false, forKey: "configurated")
        
        
        self.alias = alias!
    }
}

