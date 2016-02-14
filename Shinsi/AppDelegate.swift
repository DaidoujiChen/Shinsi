//
//  AppDelegate.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/12.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import SVProgressHUD
import FontAwesome_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        SVProgressHUD.setDefaultStyle(.Custom)
        SVProgressHUD.setBackgroundColor(UIColor(white: 0, alpha: 0.7))
        SVProgressHUD.setForegroundColor(UIColor(white: 1, alpha: 0.9))
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: -60), forBarMetrics: .Default)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName : UIFont.fontAwesomeOfSize(22)], forState: .Normal)
        return true
    }


}

