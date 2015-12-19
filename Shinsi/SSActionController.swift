//
//  SSActionController.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/16.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit
import XLActionController
import EZSwiftExtensions

struct HeaderData {
    var gdata : GData!
    var favoriteHandler : (GData -> ())!

    init( gdata : GData!, favoriteHandler : (GData -> ())!) {
        self.gdata = gdata
        self.favoriteHandler = favoriteHandler
    }
}

class TagCell: ActionCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    func initialize() {
        backgroundColor = .clearColor()
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        selectedBackgroundView = backgroundView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        let path = UIBezierPath(roundedRect: CGRectInset(rect, 2, 2), cornerRadius: 2)
        UIColor.whiteColor().set()
        path.stroke()
    }
}

class HeaderView: UICollectionReusableView {

    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var favoriteButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    func initialize() {
        self.backgroundColor = UIColor.clearColor()
    }
}

class SSActionControler : ActionController< TagCell, String, HeaderView, HeaderData, UICollectionReusableView, Void> {

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        return blurView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.backgroundColor = UIColor.init(white: 0.1, alpha: 0.5)
        
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16)
        collectionView.clipsToBounds = false

        blurView.frame = CGRectMake(0, 20, collectionView.bounds.width, contentHeight + 200)
        blurView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(.FlexibleBottomMargin)
        collectionView.addSubview(blurView)
        collectionView.sendSubviewToBack(blurView)
    }

    override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: NSBundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        settings.behavior.bounces = true
        settings.behavior.scrollEnabled = true
        settings.animation.scale = nil
        settings.animation.present.springVelocity = 0.0

        cellSpec = .NibFile(nibName: "TagCell", bundle: nil, height: { _ in 40 })
        headerSpec = .NibFile(nibName: "HeaderView", bundle: nil, height:{ _ in 150 })

        onConfigureCellForAction = { cell, action, indexPath in
            cell.setup(action.data, detail: nil, image: nil)
        }

        onConfigureHeader = { (header: HeaderView, data: HeaderData)  in
            header.titleLabel.text = data.gdata.title
            header.coverImageView.sd_setImageWithURL(NSURL(string: data.gdata.coverUrl)!)
            header.favoriteButton.addTarget(self, action: "favoriteButtonDidClick", forControlEvents: .TouchUpInside)
            header.addTapGesture(tapNumber: 1) { ges in
                if ges.state == .Ended {
                    self.dismiss()
                }
            }
        }
    }

    func favoriteButtonDidClick() {
        guard let headerData = headerData else { return }
        headerData.favoriteHandler(headerData.gdata)
        self.dismiss()
    }

    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let action = self.actionForIndexPath(actionIndexPathFor(indexPath)),
              let actionData = action.data ,
              let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        else { return CGSizeZero }

        let rows = floor(collectionView.w / 120)
        let width = (collectionView.w - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (rows - 1)) / rows
        return CGSize(width: width, height: cellSpec.height(actionData))
    }
}
