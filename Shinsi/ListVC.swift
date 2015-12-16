//
//  ListVC.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/12.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
import Async
import SDWebImage
import EZSwiftExtensions
import MWPhotoBrowser
import SDWebImage
import MJRefresh
import SVProgressHUD

class ListVC: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var searchTextField: UITextField!

    var items : [Doujinshi] = []
    var pages : [Page] = []
    var currentPage = 0
    var dataSource : SSPhotoDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let footer = MJRefreshAutoNormalFooter(refreshingBlock: {
            self.currentPage += 1
            self.loadPage(self.currentPage)
        })
        footer.setTitle("Pull to load next page", forState: .Idle)
        footer.setTitle("Loading more ...", forState: .Refreshing)
        self.collectionView.mj_footer = footer

        if let keyword = NSUserDefaults.standardUserDefaults().stringForKey("savedKeyword") {
            self.searchTextField.text = keyword
        }

        RequestManager.thumbnailMode()
        loadPage(currentPage)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.enabled = false
    }

    func loadPage(page : Int) {
        SVProgressHUD.show()

        RequestManager.getDoujinshiAtPage( page, searchWithKeyword:searchTextField.text, finishBlock: { items in
            SVProgressHUD.dismiss()
            self.items += items
            self.collectionView.reloadData()
            self.collectionView.mj_footer.endRefreshing()
        })
    }

    @IBAction func favoriteButtonDidClick(sender: UIBarButtonItem) {
        guard self.searchTextField.text != "favorites" else { return }

        self.searchTextField.text = "favorites"
        self.searchTextField.resignFirstResponder()
        reloadeData()
    }

    func searchTag(tag : String!) {
        self.searchTextField.text = "tag:\(tag)"
        reloadeData()
    }

    func reloadeData() {
        items = []
        collectionView.reloadData()
        currentPage = 0
        loadPage(currentPage)
        NSUserDefaults.standardUserDefaults().setObject(self.searchTextField.text, forKey: "savedKeyword")
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension ListVC : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        items = []
        collectionView.reloadData()
        currentPage = 0
        loadPage(currentPage)
        textField.resignFirstResponder()
        NSUserDefaults.standardUserDefaults().setObject(textField.text, forKey: "savedKeyword")
        return false
    }
}

extension ListVC : UICollectionViewDelegate, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        cell.layer.cornerRadius = 4
        cell.clipsToBounds = true

        let doujinshi = items[indexPath.row]
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.sd_setImageWithURL(NSURL(string: doujinshi.coverUrl!), placeholderImage: nil, options: [.HandleCookies])
        let label = cell.viewWithTag(2) as! UILabel
        label.text = doujinshi.title
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let doujinshi = items[indexPath.row]

        let browser = SSPhotoBrowser()
        dataSource = SSPhotoDataSource(doujinshi: doujinshi , withBrowser: browser)
        browser.delegate = dataSource
        browser.zoomPhotosToFill = false
        browser.enableGrid = true
        browser.displayActionButton = false
        //browser.startOnGrid = true
        self.navigationController?.pushViewController(browser, animated: true)

    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let rows = floor(collectionView.w / 120)
        let width = (collectionView.w - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (rows - 1)) / rows
        return CGSize(width: width, height: width / 210 * 297)
    }
}










