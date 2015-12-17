//
//  RequestManager.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/12.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
import Async

struct Doujinshi {
    var coverUrl : String!
    var title : String = ""
    var url :String!
}

struct Page {
    var thumbUrl : String!
    var url : String!
}

struct GData {
    var filecount : Int
    var rating : Float
    var tags : [String]
    var title : String
    var title_jpn : String
    var coverUrl : String
}

class RequestManager {

    //Create a config cookie.
    //Set display mode to thumbnail. (Easily get cover)
    //Set page thumbnail size to large. (Easily get page thumbnail)
    class func thumbnailMode() {
        print(__FUNCTION__)
        var hasCookie = false
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            for c in cookies {
                if c.name == "uconfig" && c.value == kUConfig {
                    hasCookie = true
                    break
                }
            }
        }

        if hasCookie == false {
            let properties = [
                NSHTTPCookieName : "uconfig" ,
                NSHTTPCookieValue : kUConfig ,
                NSHTTPCookieDomain : ".exhentai.org",
                NSHTTPCookiePath : "/" ,
                NSHTTPCookieExpires : NSDate(timeIntervalSinceNow: 262973) ,
            ]
            NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(NSHTTPCookie(properties: properties)!)
        }
    }

    class func getDoujinshiAtPage(page : Int , searchWithKeyword keyword : String? = nil , finishBlock block : ((items : [Doujinshi]) -> ())?) {
        //print(__FUNCTION__)

        var urlWithFilter = kHost + "/?page=\(page)&f_doujinshi=1&f_manga=1&f_artistcg=0&f_gamecg=0&f_western=0&f_non-h=0&f_imageset=0&f_cosplay=0&f_asianporn=0&f_misc=0&f_apply=Apply+Filter"

        if var keyword = keyword {
            print(keyword)
            if keyword.contains("tag:") {
                keyword = keyword.stringByReplacingOccurrencesOfString("tag:", withString: "")
                urlWithFilter =  kHost + "/tag/\(keyword.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)/\(page)"
            } else if keyword == "favorites" {
                urlWithFilter = kHost + "/favorites.php?page=\(page)"
            }
            else {
                urlWithFilter += "&f_search=\(keyword.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)"
            }
        }

        print(urlWithFilter)
        Alamofire.request(.GET, urlWithFilter).responseString { response in

            guard let html = response.result.value else {
                block?(items: [])
                return
            }

            if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var items : [Doujinshi] = []
                for link in doc.xpath("//div [@class='id3'] //a") {
                    if let url = link["href"] {
                        if let imgNode = link.at_css("img") {
                            if let imgUrl = imgNode["src"] , let title = imgNode["title"] {
                                items.append(Doujinshi(coverUrl: imgUrl, title: title ,url: url))
                            }
                        }
                    }
                }
                block?(items: items)
            } else {
                block?(items: [])
            }
        }
    }

    class func getDoujinshiPages(doujinshi : Doujinshi!, atPage page : Int! , finishBlock block : ((pages : [Page]) -> ())?) {
        //print(__FUNCTION__)
        let url = doujinshi.url + "?p=\(page)"
        Alamofire.request(.GET, url).responseString { response in

            guard let html = response.result.value else {
                block?(pages: [])
                return
            }
            //print(html)
            if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var pages : [Page] = []
                for link in doc.xpath("//div [@class='gdtl'] //a") {
                    if let url = link["href"] {
                        if let imgNode = link.at_css("img") {
                            if let thumbUrl = imgNode["src"] {
                                pages.append(Page(thumbUrl: thumbUrl, url: url))
                            }
                        }
                    }
                }
                block?(pages: pages)
            } else {
                block?(pages: [])
            }
        }
    }

    class func getImageURLInPageWithURL(url : String! ,finishBlock block : ( (imageURL : String?) -> () )?) {
        //print(__FUNCTION__)

        Alamofire.request(.GET, url).responseString { response in
            guard let html = response.result.value else {
                block?(imageURL: nil)
                return
            }

            if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                if let imageNode = doc.at_xpath("//img [@id='img']") {
                    if let imageURL = imageNode["src"] {
                        block?(imageURL: imageURL)
                        return
                    }
                }
            }
            block?(imageURL: nil)
        }
    }

    class func getGData( doujinshi : Doujinshi! , finishBlock block : ( (gdata : GData?) -> () )? ) {
        //print(__FUNCTION__)
        //Api http://ehwiki.org/wiki/API

        let r = doujinshi.url.stringByReplacingOccurrencesOfString(kHost + "/g/", withString: "")
        var gidlist = r.componentsSeparatedByString("/")
        guard gidlist.count == 3 else {
            block?(gdata: nil)
            return
        }

        let p = ["method": "gdata",
            "gidlist": [
                [gidlist[0],gidlist[1]]
            ]]
        Alamofire.request(.POST, kHost + "/api.php", parameters: p, encoding: .JSON, headers: nil).responseJSON { response in
            if let dic = response.result.value as? NSDictionary {
                print(dic["gmetadata"]![0])
                if let metadata = dic["gmetadata"]?[0] {
                    if let count = metadata["filecount"]  as? String ,
                        let rating = metadata["rating"] as? String,
                        let title = metadata["title"] as? String,
                        let title_jpn = metadata["title_jpn"] as? String,
                        let tags = metadata["tags"] as? [String],
                        let thumb = metadata["thumb"] as? String
                    {
                        let gdata = GData(filecount: count.toInt()!, rating: rating.toFloat()!, tags: tags ,title: title , title_jpn: title_jpn , coverUrl: thumb)
                        block?(gdata: gdata)

                        //Cache 
                        let cachedURLResponse = NSCachedURLResponse(response: response.response!, data: response.data!, userInfo: nil, storagePolicy: .Allowed)
                        NSURLCache.sharedURLCache().storeCachedResponse(cachedURLResponse, forRequest: response.request!)

                        return
                    }
                }
                block?(gdata: nil)
            }
        }


    }

    class func login(username name : String! , password pw : String! , finishBlock block : (() -> ())? ) {
        //print(__FUNCTION__)

        let url = "https://forums.e-hentai.org/index.php?act=Login&CODE=01"
        let parameter = [
            "CookieDate" : "1" ,
            "b" : "d",
            "bt" : "1-1",
            "UserName" : name,
            "PassWord" : pw,
            "ipb_login_submit" : "Login!"]

        Alamofire.request(.POST, url, parameters: parameter, encoding: .URL, headers: nil).responseString { response in
            block?()
        }
    }

    class func addDoujinshiToFavorite( doujinshi : Doujinshi!) {
        //http://exhentai.org/gallerypopups.php?gid=883375&t=08ca140888&act=addfav
        //favcat=0&favnote=&submit=Add+to+Favorites

        let r = doujinshi.url.stringByReplacingOccurrencesOfString(kHost + "/g/", withString: "")
        var gidlist = r.componentsSeparatedByString("/")
        guard gidlist.count == 3 else { return }

        let url = kHost + "/gallerypopups.php?gid=\(gidlist[0])&t=\(gidlist[1])&act=addfav"
        let parameters = ["favcat" : 0 , "favnote" : "" , "submit" : "Add+to+Favorites"]
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: nil).responseString { response in
            print(response)
        }
    }
}









