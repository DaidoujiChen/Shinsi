//
//  SSPhotoBrowser.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/13.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import MWPhotoBrowser
import SVProgressHUD
import XLActionController

class SSPhotoBrowser: MWPhotoBrowser {

    lazy var gridButton : UIBarButtonItem = { [unowned self] in
        return UIBarButtonItem(image: UIImage(named: "UIBarButtonItemGrid"), style: .Plain, target: self, action: "showGridAnimated")
    }()
    lazy var flexPlace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    lazy var actionButton : UIBarButtonItem = { [unowned self] in
        return UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "actionButtonPressed:")
    }()
    lazy var progressBar : UIProgressView = {
        let p = UIProgressView(frame: CGRectMake(0, 0, 200, 2))
        p.trackTintColor = UIColor(white: 1, alpha: 0.3)
        return p
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func performLayout() {
        super.performLayout()
        //Not good but....
        self.toolBar.items = [gridButton,flexPlace,UIBarButtonItem(customView: progressBar),flexPlace,actionButton]
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        SVProgressHUD.dismiss()
    }
}

class SSPhotoDataSource : NSObject , MWPhotoBrowserDelegate {

    var doujinshi : Doujinshi!
    var gdata : GData?
    weak var browser : SSPhotoBrowser!
    var pages : [Page] = []
    var currentPage = 0
    var totalPage = 1

    init(doujinshi aDoujinshi : Doujinshi! , withBrowser browser : SSPhotoBrowser! ) {
        super.init()
        self.doujinshi = aDoujinshi
        self.browser = browser
        getGData()
    }

    func getGData() {
        SVProgressHUD.show()
        RequestManager.getGData(self.doujinshi) { gdata in
            guard let gdata = gdata else { return }
            self.gdata = gdata
            self.totalPage = Int(ceilf(Float(gdata.filecount) / Float(20.0)))
            print("File count \(gdata.filecount).   Total page \(self.totalPage).")
            let progress = Float(self.currentPage) / Float(self.totalPage)
            self.browser.progressBar.setProgress(progress, animated: true)
            self.loadPages()
        }
    }

    func loadPages() {
        //Cancel when leave browser
        guard let _ = self.browser else {
            SVProgressHUD.dismiss()
            return
        }
        RequestManager.getDoujinshiPages(doujinshi, atPage: currentPage) {pages in
            SVProgressHUD.dismiss()
            guard let browser = self.browser else { return }

            self.pages += pages
            if self.currentPage + 1 < self.totalPage {
                if self.currentPage == 0 {
                    browser.reloadData()
                }
                self.currentPage += 1
                self.loadPages()
                let progress = Float(self.currentPage) / Float(self.totalPage)
                self.browser.progressBar.setProgress(progress, animated: true)
            } else {
                browser.enableGrid = true
                browser.reloadData()
                self.browser.progressBar.hidden = true
            }
        }
    }

    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(pages.count)
    }

    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        let page = pages[Int(index)]
        return SSPagePhoto(URL: page.url)
    }

    func photoBrowser(photoBrowser: MWPhotoBrowser!, thumbPhotoAtIndex index: UInt) -> MWPhotoProtocol! {
        let page = pages[Int(index)]
        return MWPhoto(URL: NSURL(string: page.thumbUrl!)! )
    }

    func photoBrowser(photoBrowser: MWPhotoBrowser!, actionButtonPressedForPhotoAtIndex index: UInt) {

        guard let gdata = gdata else { return }

        let actionController = SSActionControler()
        actionController.headerData = HeaderData(gdata: gdata, favoriteHandler: { gdata in
            RequestManager.addDoujinshiToFavorite(self.doujinshi)
            SVProgressHUD.showSuccessWithStatus("Add to favorites")
        })

        for tag in gdata.tags {
            actionController.addAction(Action(tag, style: .Default, handler: { action in

                guard let tabBarController = photoBrowser.navigationController?.tabBarController else { return }
                guard let nv = tabBarController.viewControllers?.first as? UINavigationController else { return }
                guard let searchVC = nv.viewControllers.first as? ListVC else { return }

                tabBarController.selectedIndex = 0
                searchVC.searchTag(tag)
                photoBrowser.navigationController?.popViewControllerAnimated(true)
            }))
        }
        photoBrowser.presentViewController(actionController, animated: true, completion: nil)
    }
}