//
//  UIScrollView+Extension.swift
//  HBSwiftPublicModule
//
//  Created by HNL on 2022/11/3.
//

import UIKit

private var kRightSideView = ""

extension UIScrollView {
    
    var rightSideRefreshView: UIView? {
        set {
            objc_setAssociatedObject(self, &kRightSideView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let view = objc_getAssociatedObject(self, &kRightSideView) as? UIView else { return nil }
            return view
        }
    }
    
    @objc
    public func configRightSideRefresh(with refrehser: UIView & UIScrollViewRightRefreshProtocol,
                                       sideViewHeight: CGFloat,
                                       isUpdateContentLocationInTheBeginning: Bool,
                                       noRefreshViewInsetRight: CGFloat,
                                       rightRefreshViewInsetRight: CGFloat,
                                       action:@escaping () -> ()) {
        let newContainer = RefreshRightContainer(delegate: refrehser,
                              noRefreshViewInsetRight: noRefreshViewInsetRight,
                              rightRefreshViewInsetRight: rightRefreshViewInsetRight,
                              isUpdateContentLocationInTheBeginning: isUpdateContentLocationInTheBeginning,
                              refreshAction: action)
        newContainer.frame = CGRect(x: 0, y: 0, width: refrehser.frame.size.width, height: sideViewHeight)
        newContainer.addSubview(refrehser)
        self.insertSubview(newContainer, at: 0)
        self.rightSideRefreshView = newContainer
        refrehser.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        refrehser.frame = newContainer.bounds
    }
    
    @objc
    public func removeRightSideRefreshView() {
        self.rightSideRefreshView?.removeFromSuperview()
    }
}
