//
//  LoginVC.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/13.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import SVProgressHUD

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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(animated: Bool) {

        super.viewDidAppear(animated)

        if checkCookie() {
            pustToListVC()
        } else {
            userNameField.hidden = false
            passwordField.hidden = false
            loginButton.hidden = false
        }
    }

    func pustToListVC() {
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("ListVC") as! ListVC
        self.navigationController?.setViewControllers([vc], animated: false)
    }

    func checkCookie() -> Bool {
        //print(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies)
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
                self.pustToListVC()
            } else {
                print("Login failed")
                SVProgressHUD.showErrorWithStatus("Login failed")
            }
        }
    }
}
