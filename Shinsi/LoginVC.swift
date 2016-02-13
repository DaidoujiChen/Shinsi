//
//  LoginVC.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/13.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import SVProgressHUD

class SSNavigationController : UINavigationController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

class LoginVC: UIViewController {

    @IBOutlet var userNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userNameField.hidden = true
        passwordField.hidden = true
        loginButton.hidden = true
    }

    override func viewDidAppear(animated: Bool) {

        super.viewDidAppear(animated)

        if checkCookie() {
            pustToList()
        } else {
            userNameField.hidden = false
            passwordField.hidden = false
            loginButton.hidden = false
        }
    }

    func pustToList() {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("ListVC") as! ListVC
        navigationController?.setViewControllers([vc], animated: false)
    }

    func checkCookie() -> Bool {
        print(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies)
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(NSURL(string: kEHentaiURL)!) {
            for c in cookies {
                if c.name == "ipb_pass_hash" {
                    return true
                }
            }
        }
        return false
    }

    func copyCookiesForEx() {
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(NSURL(string: kEHentaiURL)!) {
            print(cookies)
            for c in cookies {
                if var properties = c.properties {
                    properties["Domain"] = ".exhentai.org"
                    if let newCookie = NSHTTPCookie(properties: properties) {
                        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(newCookie)
                    }
                }
            }
        }
    }

    @IBAction func login(sender: AnyObject) {
        SVProgressHUD.show()

        guard let name = userNameField.text , let pw = passwordField.text else { return }
        RequestManager.login(username: name, password: pw) {
            SVProgressHUD.dismiss()

            if self.checkCookie() {
                self.copyCookiesForEx()
                self.pustToList()
            } else {
                print("Login failed")
                SVProgressHUD.showErrorWithStatus("Login failed")
            }
        }
    }
}
