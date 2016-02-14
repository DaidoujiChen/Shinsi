//
//  DownloadManager.swift
//  Shinsi
//
//  Created by PowHu Yang on 2016/02/14.
//  Copyright © 2016年 PowHu. All rights reserved.
//

import Foundation
import RealmSwift
import SDWebImage

class DownloadManager {

    class func downloadDoujinshi(doujinshi : Doujinshi! , gdata : GData! , pages : [Page] , progressBlock : ((Float) -> ())?) {

        let realm = try! Realm()
        doujinshi.gdata = gdata

        let totalCount = pages.count * 2
        var finishedCount = 0
        for p in pages {
            doujinshi.pages.append(p)
            let pageURL = p.url
            let thumbURL = p.thumbUrl

            //Big image
            let imageCache = SDWebImageManager.sharedManager().imageCache
            imageCache.queryDiskCacheForKey(pageURL) { image, cacheType in
                if let _ = image {
                    //Already download
                    finishedCount += 1
                    progressBlock?(Float(finishedCount) / Float(totalCount))
                } else {
                    RequestManager.getImageURLInPageWithURL(pageURL) { url in
                        guard let url = url else { return }
                        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(NSURL(string: url)!, options: [.HighPriority , .HandleCookies ], progress: nil, completed: { (image, data, error, success) -> Void in
                            if let image = image {
                                imageCache.storeImage(image, forKey:pageURL)
                            }
                            finishedCount += 1
                            progressBlock?(Float(finishedCount) / Float(totalCount))
                        })
                    }
                }
            }

            //Thumb
            imageCache.queryDiskCacheForKey(thumbURL){ image, cacheType in
                if let _ = image {
                    //Already download
                    finishedCount += 1
                    progressBlock?(Float(finishedCount) / Float(totalCount))
                } else {
                    SDWebImageDownloader.sharedDownloader().downloadImageWithURL(NSURL(string: thumbURL)!, options: [.HighPriority , .HandleCookies ], progress: nil, completed: { (image, data, error, success) -> Void in
                        if let image = image {
                            imageCache.storeImage(image, forKey:thumbURL)
                        }
                        finishedCount += 1
                        progressBlock?(Float(finishedCount) / Float(totalCount))
                    })
                }
            }
        }
        try! realm.write {
            realm.add(doujinshi)
            print("Insert to realm : \(doujinshi)")
        }
    }
}

