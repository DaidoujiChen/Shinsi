//
//  PhotoBrowserVC.swift
//  Shinsi
//
//  Created by PowHu Yang on 2016/02/09.
//  Copyright © 2016年 PowHu. All rights reserved.
//

import UIKit
import SVProgressHUD
import XLActionController
import Async
import SKPhotoBrowser
import RealmSwift
import SDWebImage

class PhotoBrowserVC: UIViewController {

    @IBOutlet var downloadButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    var doujinshi : Doujinshi!
    var gdata : GData?
    var pages : [Page] = []
    var currentPage = 0
    var totalPage = 1
    var browser : SKPhotoBrowser?
    lazy var progressbar : UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .Bar)
        bar.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
        bar.trackTintColor = .clearColor()
        bar.progressTintColor = .whiteColor()
        if let navBar = self.navBar {
            bar.frame = navBar.bounds
            navBar.addSubview(bar)
            print(bar.frame)
        }
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if doujinshi.gdata != nil{
            print("Load form downloaded")
            gdata = doujinshi.gdata
            title = gdata!.title
            var ps = [Page]()
            for p in doujinshi.pages {
                ps.append(p)
            }
            self.pages = ps
            downloadButton.enabled = false
        } else {
            getGData()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    func reloadData() {
        collectionView.reloadData()
    }

    func getGData() {
        SVProgressHUD.show()
        RequestManager.getGData(self.doujinshi) { [weak self] gdata in
            guard let gdata = gdata else { return }
            guard let weakSelf = self else { return }
            weakSelf.title = gdata.title
            weakSelf.gdata = gdata
            weakSelf.totalPage = Int(ceilf(Float(gdata.filecount) / Float(20.0)))
            print("File count \(gdata.filecount).   Total page \(weakSelf.totalPage).")
            //let progress = Float(weakSelf.currentPage) / Float(weakSelf.totalPage)
            weakSelf.loadPages()
        }
    }
    
    func loadPages() {

        RequestManager.getDoujinshiPages(doujinshi, atPage: currentPage) { [weak self] pages in

            SVProgressHUD.dismiss()
            guard let weakSelf = self else { return }

            weakSelf.pages += pages
            weakSelf.reloadData()

            if let browser = weakSelf.browser {
                var images = [SSPhoto]()
                for p in pages {
                    images.append(SSPhoto(URL: p.url))
                }
                browser.appendPhotos(images)
            }

            if weakSelf.currentPage + 1 < weakSelf.totalPage {
                weakSelf.currentPage += 1
                weakSelf.loadPages()
            }
        }
    }

    @IBAction func downloadButtonDidClick(sender: UIBarButtonItem) {
        guard let gdata = gdata else { return }
        downloadButton.enabled = false
        DownloadManager.downloadDoujinshi(doujinshi, gdata: gdata, pages: pages){ progress in
            print(progress)
            self.progressbar.setProgress(progress, animated: true)
            self.progressbar.hidden = progress >= 1 ? true : false
        }
    }

    @IBAction func actionButtonDidClick(sender: UIBarButtonItem) {
        guard let gdata = gdata else { return }

        let actionController = SSActionControler()
        actionController.headerData = HeaderData(gdata: gdata, favoriteHandler: { gdata in
            RequestManager.addDoujinshiToFavorite(self.doujinshi)
            SVProgressHUD.showSuccessWithStatus("Add to favorites")
        })

        for tag in gdata.tags {
            actionController.addAction(Action(tag.name, style: .Default, handler: { action in

                guard let nv = self.navigationController else { return }
                guard let searchVC = nv.storyboard?.instantiateViewControllerWithIdentifier("ListVC") as? ListVC else { return }
                searchVC.searchString = "tag:\(tag.name)"
                nv.pushViewController(searchVC, animated: true)
            }))
        }
        self.presentViewController(actionController, animated: true, completion: nil)
    }

}

extension PhotoBrowserVC : UICollectionViewDataSource , UICollectionViewDelegate , UICollectionViewDelegateFlowLayout ,SKPhotoBrowserDelegate {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)

        let page = pages[indexPath.row]
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.sd_setImageWithURL(NSURL(string: page.thumbUrl), placeholderImage: nil, options: [.HandleCookies])
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var images = [SSPhoto]()
        let cell = collectionView.cellForItemAtIndexPath(indexPath)!
        let imageView = cell.viewWithTag(1) as! UIImageView
        guard let fromImage = imageView.image else { return }
        for p in pages {
            images.append(SSPhoto(URL: p.url))
        }
        browser = SKPhotoBrowser(originImage: fromImage, photos: images, animatedFromView: cell)
        browser!.initializePageIndex(indexPath.row)
        browser!.delegate = self
        browser!.displayAction = false
        browser!.displayBackAndForwardButton = false
        presentViewController(browser!, animated: true, completion: {})
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let rows = min(4, floor(collectionView.w / 120))
        let width = (collectionView.w - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (rows - 1)) / rows
        return CGSize(width: width, height: width / 250 * 353)
    }

    func didShowPhotoAtIndex(index: Int) {
        // do some handle if you need
    }

    func willDismissAtPageIndex(index: Int) {
        // do some handle if you need
    }

    func willShowActionSheet(photoIndex: Int) {
        // do some handle if you need
    }

    func didDismissAtPageIndex(index: Int) {
        // do some handle if you need
    }

    func didDismissActionSheetWithButtonIndex(buttonIndex: Int, photoIndex: Int) {
        // handle dismissing custom actions
    }
}
