//
//  AppDelegate.swift
//  Nabi
//
//  Created by aaron.du on 2018/9/26.
//  Copyright © 2018年 aaron.du. All rights reserved.
//

import UIKit
import CoreData
import CACBaseObjC
import Firebase
import Messages

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    var registToken : String?
    var window: UIWindow?
    public var switchType : String? // 1.online 2.staging 3.lab
    var baseURLHandler = BaseURL()
    var rootView : ViewController?
    var announcementHandler : AnnouncementHandler!
    let userDefault = UserDefaults.standard

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print("call didFinishLaunchingWithOptions")
        
        
        FirebaseApp.configure()
        
        baseURLHandler = BaseURL.init()
        //baseURLHandler?.stagingHelper(withDefaultColor: UIColor.white, withStagingColor: UIColor.red)
        announcementHandler = AnnouncementHandler.init(userDefaults: UserDefaults.standard, withCustomBlockImageName: "")
        announcementHandler.delegate = self
        baseURLHandler?.create()
        self.switchType = baseURLHandler?.getString()
        if switchType == "lab" {
            Domain.CONNECT_DOMAIN = "https://nabi.104-dev.com.tw/"
            Domain.COOKIE_DOMAIN = "nabi.104-dev.com.tw"
        }else if switchType == "staging" {
            Domain.CONNECT_DOMAIN = "https://nabi.104-staging.com.tw/"
            Domain.COOKIE_DOMAIN = "nabi.104-staging.com.tw"
        }else if switchType == "online" {
            Domain.CONNECT_DOMAIN = "https://nabi.104.com.tw/"
            Domain.COOKIE_DOMAIN = "nabi.104.com.tw"
        }
        //baseURLHandler?.setURLWithEnvironmentState(Int32(LAB.rawValue))
        if let tokenValue = userDefault.object(forKey: Domain.NABI_COOKIE_NAME) as? String , tokenValue.count > 0 {
            //如果有註冊到tooken
            print ("get userDefault Object ===  \(tokenValue)")
            self.registToken = tokenValue
            setNabiCooke(cookieName: Domain.NABI_COOKIE_NAME , cookieValue: self.registToken)
        }
        
        setNabiCooke(cookieName: Domain.NABI_COOKIE_NAME_DEVICE_ID, cookieValue: self.getUDID())
        
        setNabiCooke(cookieName: Domain.NABI_COOKIE_NAME_DEVICE_TYPE, cookieValue: "ios")
        
        //改變status bar顏色
        
        //註冊 push token
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        Messaging.messaging().delegate = self
        
        if let windowRootView = self.window?.rootViewController as? ViewController {
            self.rootView = windowRootView
        }

        return true
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
        announcementHandler.closeCustomAlert()
        announcementHandler.getAnnouncementWithURL(baseURLHandler?.getAnnouncementURLString())
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                self.setTokenToUserDefault(token: result.token)
                self.setNabiCooke(cookieName: Domain.NABI_COOKIE_NAME , cookieValue: self.registToken)
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext()
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// iOS 10以前點擊push
    /// - Parameters:
    ///   - application:
    ///   - userInfo:
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {

        self.handleNotificationPush(userInfo: userInfo)
    }
    //iOS 點擊push時候觸發
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("call userNotificationCenter didReceive response ")
        self.handleNotificationPush(userInfo: response.notification.request.content.userInfo)
    }
    /// iOS in application 收到push時候觸發
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        //目前決議 iOS in application的時候不做處理
        //self.handleNotificationPush(userInfo: userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }
    

    
    // MARK: - Firebase message delegate token刷新
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)

        setTokenToUserDefault(token: fcmToken)
        setNabiCooke(cookieName: Domain.NABI_COOKIE_NAME , cookieValue: self.registToken)
        
    }
    
    // MARK: - private func
    
    func getUDID() -> String {
        
        if let udidValue = userDefault.object(forKey: Domain.NABI_COOKIE_NAME_DEVICE_ID) as? String , udidValue.count > 0 {
            //如果有註冊到tooken
            print ("get userDefault device id ===  \(udidValue)")
            return udidValue
        }
        
        //如果userDefault沒有，就建立一個新的
        let uuid = NSUUID().uuidString
        userDefault.set(uuid, forKey: Domain.NABI_COOKIE_NAME_DEVICE_ID)
        userDefault.synchronize()
        
        print ("create new UDID ===  \(uuid)")
        return uuid
    }
    
    /// 統一處理Nabi 收到的 Notification push
    /// - Parameter userInfo: Notification收到的userInfo資料
    func handleNotificationPush(userInfo: [AnyHashable: Any]){
        
        let state = UIApplication.shared.applicationState
        
        if state == .background {
            // background
            print("state == .background")
        }else if state == .inactive {
            print("state == .inactive")
        }else if state == .active {
            print("state == .active 前景")
        }
        
        
        // Print full message.
        print(userInfo)

        if let redirectURL = userInfo["redirectUrl"] as? String {
            self.rootView?.setURLReload(urlString: redirectURL)
        }
        
        
    }
    
    /// 將 fcm token 放入userDefault中
    /// - Parameter token: fcm token
    func setTokenToUserDefault(token: String) {
        self.registToken = token
        userDefault.set(token, forKey: Domain.NABI_COOKIE_NAME)
        userDefault.synchronize()
    }
    
    
    /// 將資料放入Cookie中 , expires 90天
    /// - Parameter cookieName: 要存放於cookie的名稱
    func setNabiCooke(cookieName: String , cookieValue: String?) {
        //要先刪除掉 NABIAPPSID
        
        let cstorage = HTTPCookieStorage.shared
        if let cookies = cstorage.cookies {
            for cookie in cookies where cookie.name == cookieName {
                cstorage.deleteCookie(cookie)
            }
        }
        
        //创建一个HTTPCookie对象
        var props = Dictionary<HTTPCookiePropertyKey, Any>()
        props[HTTPCookiePropertyKey.name] = cookieName
        props[HTTPCookiePropertyKey.value] = cookieValue ?? ""
        props[HTTPCookiePropertyKey.path] = "/"
        props[HTTPCookiePropertyKey.domain] = Domain.COOKIE_DOMAIN
        props[HTTPCookiePropertyKey.expires] = Date().addingTimeInterval(3600*24*90)
        let cookie = HTTPCookie(properties: props)
         
        //通过setCookie方法把Cookie保存起来
        cstorage.setCookie(cookie!)
        
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
    }
    
    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Nabi")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    @available(iOS 10.0 , *)
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL,
                             options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.host == nil {
            return true;
        }
        
        
        //baseURLHandler?.getMobileBaseURLString()
        if(url.scheme == "m104nabi"){
            let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false)
            
            if(components?.host == "switch"){
                _ = baseURLHandler?.setURLWith(url)
                self.switchType = baseURLHandler?.getString()
                //logout()
                if switchType == "lab" {
                    Domain.CONNECT_DOMAIN = "https://nabi.104-dev.com.tw/"
                }else if switchType == "staging" {
                    Domain.CONNECT_DOMAIN = "https://nabi.104-staging.com.tw/"
                }else if switchType == "online" {
                    Domain.CONNECT_DOMAIN = "https://nabi.104.com.tw/"
                }
            }
        }
        return true
    }
}
// MARK: - AnnouncementHandlerDelegate
extension AppDelegate: AnnouncementHandlerDelegate {
    
    func didFinishConnecting(_ model: AnnouncementModel!) {
        if let model = model {
            if let btn1 = model.btn1 {
                if btn1 == "1" {
                    
                }else{
                    
                }
                
            }
        }
    }
    
}

extension NSURL {
    var fragments: [String: String] {
        var results = [String: String]()
        if let pairs = self.fragment?.components(separatedBy: "?"), pairs.count > 0 {
            for pair: String in pairs {
                if let keyValue = pair.components(separatedBy: "=") as [String]? {
                    results.updateValue(keyValue[1], forKey: keyValue[0])
                }
            }
        }
        return results
    }
}
