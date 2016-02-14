//
//  RealmModel.swift
//  Shinsi
//
//  Created by PowHu Yang on 2016/02/13.
//  Copyright © 2016年 PowHu. All rights reserved.
//

import Foundation
import RealmSwift

class RealmManager {

    class func getDownloadedDoujinshi() -> [Doujinshi] {
        let realm = try! Realm()
        let results = realm.objects(Doujinshi)
        var books = [Doujinshi]()
        for d in results {
            books.append(d)
        }
        return books
    }
}

class Doujinshi : Object {
    dynamic var coverUrl = ""
    dynamic var title = ""
    dynamic var url = ""

    let pages = List<Page>()
    dynamic var gdata : GData?
}

class Page : Object {
    dynamic var thumbUrl = ""
    dynamic var url = ""
}

class GData : Object {
    dynamic var filecount = 0
    dynamic var rating : Float = 0.0
    dynamic var title = ""
    dynamic var title_jpn = ""
    dynamic var coverUrl = ""
    let tags = List<Tag>()
}

class Tag : Object {
    dynamic var name = ""
}