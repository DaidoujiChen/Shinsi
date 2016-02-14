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

    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var searchTextField: UITextField!

    var items : [Doujinshi] = []
    var pages : [Page] = []
    var currentPage = 0

    var searchString : String?

    override func viewDidLoad() {
        super.viewDidLoad()

        let footer = MJRefreshAutoNormalFooter(refreshingBlock: {
            self.currentPage += 1
            self.loadPage(self.currentPage)
        })
        footer.setTitle("Pull to load next page", forState: .Idle)
        footer.setTitle("Loading more ...", forState: .Refreshing)
        footer.setTitle("No more data", forState: .NoMoreData)
        collectionView?.mj_footer = footer

        if let searchString = searchString {
            self.searchTextField.text = searchString
        }
        else if let keyword = NSUserDefaults.standardUserDefaults().stringForKey("savedKeyword") {
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
        //self.navigationController?.interactivePopGestureRecognizer?.enabled = false
    }

    func loadPage(page : Int) {

        if searchTextField.text == "downloaded" {
            items = RealmManager.getDownloadedDoujinshi()
            collectionView?.reloadData()
            collectionView?.mj_footer.state = .NoMoreData
        }
        else {
            SVProgressHUD.show()

            RequestManager.getDoujinshiAtPage( page, searchWithKeyword:searchTextField.text, finishBlock: { items in
                SVProgressHUD.dismiss()
                self.collectionView?.mj_footer.endRefreshing()
                if items.count > 0 {
                    self.items += items
                    self.collectionView?.reloadData()
                } else {
                    self.collectionView?.mj_footer.state = .NoMoreData
                }
            })
        }
    }

    func searchTag(tag : String!) {
        self.searchTextField.text = "tag:\(tag)"
        reloadeData()
    }

    func reloadeData() {
        items = []
        collectionView?.reloadData()
        currentPage = 0
        loadPage(currentPage)
        if searchString == nil {
            NSUserDefaults.standardUserDefaults().setObject(self.searchTextField.text, forKey: "savedKeyword")
        }
    }

    @IBAction func favoriteButtonDidClick(sender: UIBarButtonItem) {
        self.searchTextField.text = "favorites"
        reloadeData()
    }

    @IBAction func downloadedButtonDidClick(sender: UIBarButtonItem) {
        self.searchTextField.text = "downloaded"
        reloadeData()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }
}

extension ListVC : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        reloadeData()
        textField.resignFirstResponder()
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
        imageView.sd_setImageWithURL(NSURL(string: doujinshi.coverUrl), placeholderImage: nil, options: [.HandleCookies])
        let label = cell.viewWithTag(2) as! UILabel
        label.text = doujinshi.title
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let doujinshi = items[indexPath.row]
        guard let browser = storyboard?.instantiateViewControllerWithIdentifier("PhotoBrowserVC") as? PhotoBrowserVC else { return }
        browser.doujinshi = doujinshi
        navigationController?.pushViewController(browser, animated: true)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let rows = min(5, floor(collectionView.w / 120))
        let width = (collectionView.w - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (rows - 1)) / rows
        return CGSize(width: width, height: width / 250 * 353)
    }
}










