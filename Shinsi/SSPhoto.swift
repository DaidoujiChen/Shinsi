//
//  SSPhoto.swift
//  Shinsi
//
//  Created by PowHu Yang on 2016/02/09.
//  Copyright © 2016年 PowHu. All rights reserved.
//

import Foundation
import SKPhotoBrowser
import Async
import SDWebImage

class SSPhoto : NSObject, SKPhotoProtocol {
    
    var underlyingImage :UIImage!
    var urlString :String!
    var caption :String!
    private var imageOperation :SDWebImageOperation?
    var isLoading = false

    init(URL url : String!) {
        urlString = url
    }

    func loadUnderlyingImageAndNotify() {
        guard isLoading == false else { return }
        //print("Start load \(urlString)")
        isLoading = true
        let imageCache = SDWebImageManager.sharedManager().imageCache
        RequestManager.getImageURLInPageWithURL(self.urlString) { url in
            guard let url = url else {
                self.imageLoadComplete()
                return
            }

            let manager = SDWebImageManager.sharedManager()
            self.imageOperation = manager.downloadImageWithURL( NSURL(string: url)! , options: [.HighPriority , .CacheMemoryOnly], progress:nil , completed: { image, error, imageCacheType, bool, url in
                imageCache.storeImage(image, forKey: self.urlString)
                self.underlyingImage = image
                Async.main{
                    self.imageLoadComplete()
                }
            })
        }
    }

    func checkCache() {
        let imageCache = SDWebImageManager.sharedManager().imageCache
        if let memoryCache = imageCache.imageFromMemoryCacheForKey(urlString) {
            underlyingImage = memoryCache
            imageLoadComplete()
            return
        }

        imageCache.queryDiskCacheForKey(self.urlString) { image, cacheType in
            if let diskCache = image {
                self.underlyingImage = diskCache
                self.imageLoadComplete()
            }
        }
    }

    func imageLoadComplete() {
        isLoading = false
        NSNotificationCenter.defaultCenter().postNotificationName(SKPHOTO_LOADING_DID_END_NOTIFICATION, object: self)
    }
}