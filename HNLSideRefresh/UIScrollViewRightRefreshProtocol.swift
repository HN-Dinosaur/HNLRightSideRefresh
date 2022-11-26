//
//  UIScrollViewRightRefreshProtocol.swift
//  HBSwiftPublicModule
//
//  Created by HNL on 2022/11/3.
//

import UIKit

@objc
public protocol UIScrollViewRightRefreshProtocol: AnyObject {
    func didCompleteRefresh()
    func updateContentLocation(draggingDistance: CGFloat)
    /**
     拖动百分比变化的回调
    
     - parameter percent: 拖动百分比
     */
    func percentUpdateDuringScrolling(_ percent: CGFloat)
}

@objc
public enum DraggingActionText: Int {
    case scrollToAction
    case releaseToAction
}
