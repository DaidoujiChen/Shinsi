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

class SSPhotoBrowser: MWPhotoBrowser {

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        SVProgressHUD.dismiss()
    }

}

class SSPhotoDataSource : NSObject , MWPhotoBrowserDelegate {

    var url : String!
    weak var browser : SSPhotoBrowser!
    var pages : [Page] = []
    var currentPage = 0
    var totalPage = 1

    init(URL url : String! , withBrowser browser : SSPhotoBrowser! ) {
        super.init()
        self.url = url
        self.browser = browser
        getGData()
    }

    func getGData() {
        SVProgressHUD.showWithStatus("Fetching gdata")
        RequestManager.getGData(self.url) { gdata in
            guard let gdata = gdata else { return }
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

        SVProgressHUD.showProgress( Float(currentPage) / Float(totalPage), status: "Parsing page \(currentPage) of \(totalPage)")
        print( "Load page \(currentPage)")

        RequestManager.getPages("\(self.url)?p=\(self.currentPage)") {pages in

            self.pages += pages
            if self.currentPage + 1 < self.totalPage {
                self.currentPage += 1
                self.loadPages()
            } else {
                SVProgressHUD.dismiss()
                guard let browser = self.browser else { return }
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
}