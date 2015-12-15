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
        SVProgressHUD.showWithStatus("Fetching gdata")
        RequestManager.getGData(self.doujinshi) { gdata in
            guard let gdata = gdata else { return }
            self.gdata = gdata
            self.totalPage = Int(ceilf(Float(gdata.filecount) / Float(20.0)))
            print("File count \(gdata.filecount).   Total page \(self.totalPage).")
            self.loadPages()
        }
    }

    func loadPages() {
        //Cancel when leave browser
        guard let _ = self.browser else {
            SVProgressHUD.dismiss()
            return
        }

        //SVProgressHUD.showProgress( Float(currentPage) / Float(totalPage), status: "Parsing page \(currentPage) of \(totalPage)")
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
            } else {
                browser.enableGrid = true
                browser.reloadData()
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

        let actionController = SpotifyActionController()
        actionController.headerData = SpotifyHeaderData(title: gdata.title_jpn, subtitle: "Various Artists", image: UIImage(named: "UIBarButtonItemGrid")!)

        actionController.addAction(Action(ActionData(title: "Add to favorite", image: UIImage(named: "UIBarButtonItemGrid")!), style: .Destructive, handler: { action in
            RequestManager.addDoujinshiToFavorite(self.doujinshi)
            SVProgressHUD.showSuccessWithStatus("Add to favorite")
        }))

        for tag in gdata.tags {
            actionController.addAction(Action(ActionData(title: tag, image: UIImage(named: "UIBarButtonItemGrid")!), style: .Default, handler: { action in
                if let listVC = photoBrowser.navigationController?.viewControllers.first as? ListVC {
                    listVC.searchTag(tag)
                    photoBrowser.navigationController?.popViewControllerAnimated(true)
                }
            }))
        }
        photoBrowser.presentViewController(actionController, animated: true, completion: nil)
    }
}