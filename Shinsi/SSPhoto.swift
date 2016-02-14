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
    var isLoading = false

    init(URL url : String!) {
        urlString = url
    }

    func loadUnderlyingImageAndNotify() {
        guard isLoading == false else { return }
        isLoading = true
        let imageCache = SDWebImageManager.sharedManager().imageCache
        RequestManager.getImageURLInPageWithURL(urlString) { [weak self] url in
            guard let weakSelf = self else { return }
            guard let url = url else {
                weakSelf.imageLoadComplete()
                return
            }

            SDWebImageDownloader.sharedDownloader().downloadImageWithURL( NSURL(string: url)! , options: [.HighPriority , .HandleCookies , .UseNSURLCache], progress:nil , completed: { [weak self] image, data, error, success in
                guard let weakSelf = self else { return }
                imageCache.storeImage(image, forKey: weakSelf.urlString)
                weakSelf.underlyingImage = image
                Async.main{
                    weakSelf.imageLoadComplete()
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

        imageCache.queryDiskCacheForKey(urlString) { [weak self] image, cacheType in
            if let diskCache = image , weakSelf = self {
                weakSelf.underlyingImage = diskCache
                weakSelf.imageLoadComplete()
            }
        }
    }

    func imageLoadComplete() {
        isLoading = false
        NSNotificationCenter.defaultCenter().postNotificationName(SKPHOTO_LOADING_DID_END_NOTIFICATION, object: self)
    }
}