//
//  SSTabBarController.swift
//  Shinsi
//
//  Created by PowHu Yang on 2015/12/19.
//  Copyright © 2015年 PowHu. All rights reserved.
//

import UIKit

class SSTabBarController: UITabBarController , UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self;
        self.tabBar.tintColor = UIColor.whiteColor()
    }

    override func viewWillLayoutSubviews() {
//        var tabFrame = self.tabBar.frame
//        tabFrame.size.height = 36
//        tabFrame.origin.y = self.view.frame.size.height - 36
//        self.tabBar.frame = tabFrame
    }

    func tabBarController(tabBarController: UITabBarController, animationControllerForTransitionFromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        let from = tabBarController.viewControllers!.indexOf(fromVC)!
        let to =   tabBarController.viewControllers!.indexOf(toVC)!
        let transitioning = TabBarPushTransition()
        transitioning.presenting = to > from
        return transitioning
    }

}

class TabBarPushTransition : NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = true

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        let direction : CGFloat = presenting ? 1 : -1;
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        transitionContext.containerView()?.addSubview(fromView)
        transitionContext.containerView()?.addSubview(toView)
        let endFrame = toView.bounds
        let outgoingEndFrame = CGRectOffset(fromView.bounds, -endFrame.size.width * direction, 0)
        toView.frame = CGRectOffset(fromView.bounds, fromView.frame.size.width * direction, 0)


        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: [.CurveEaseInOut], animations: {
            toView.frame = endFrame
            fromView.frame = outgoingEndFrame
            }, completion: { fin in
                toView.setNeedsUpdateConstraints()
                transitionContext.completeTransition(true)
        })
    }
}