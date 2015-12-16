//
//  SSPagePhoto.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/13.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import Async
import SDWebImage
import MWPhotoBrowser

class SSPagePhoto : NSObject, MWPhotoProtocol {

    var urlString : String
    var loadingInProgress = false
    private var imageOperation : SDWebImageOperation?

    init(URL url : String!) {
        self.urlString = url
    }

    @objc var underlyingImage : UIImage?

    @objc func caption() -> String? {
        return nil
    }

    @objc func loadUnderlyingImageAndNotify() {
        guard loadingInProgress == false else { return }
        loadingInProgress = true
        self.performLoadUnderlyingImageAndNotify()
    }

    @objc func performLoadUnderlyingImageAndNotify() {
        let imageCache = SDWebImageManager.sharedManager().imageCache
        if let memoryCache = imageCache.imageFromMemoryCacheForKey(self.urlString) {
            self.underlyingImage = memoryCache
            self.imageLoadComplete()
            return
        }

        imageCache.queryDiskCacheForKey(self.urlString) { image, cacheType in
            if let diskCache = image {
                self.underlyingImage = diskCache
                self.imageLoadComplete()
            } else {
                RequestManager.getImageURLInPageWithURL(self.urlString) { url in
                    guard let url = url else {
                        self.imageLoadComplete()
                        return
                    }

                    let manager = SDWebImageManager.sharedManager()
                    self.imageOperation = manager.downloadImageWithURL( NSURL(string: url)! , options: [.HighPriority , .CacheMemoryOnly], progress: { receivedSize, expectedSize in
                        if expectedSize > 0 {
                            let progress = Float(receivedSize) / Float(expectedSize)
                            let dict : NSDictionary = ["progress" : progress , "photo" : self]
                            NSNotificationCenter.defaultCenter().postNotificationName(MWPHOTO_PROGRESS_NOTIFICATION, object: dict)
                        }
                        }, completed: { image, error, imageCacheType, bool, url in

                            imageCache.storeImage(image, forKey: self.urlString)

                            self.underlyingImage = image
                            Async.main {
                                self.imageLoadComplete()
                            }
                    })
                }
            }
        }
    }

    @objc func unloadUnderlyingImage() {
        loadingInProgress = false
        self.underlyingImage = nil
    }

    func imageLoadComplete() {
        loadingInProgress = false
        NSNotificationCenter.defaultCenter().postNotificationName(MWPHOTO_LOADING_DID_END_NOTIFICATION, object: self)
    }
    
    @objc func cancelAnyLoading() {
        //imageOperation?.cancel()
        //loadingInProgress = false
    }
}