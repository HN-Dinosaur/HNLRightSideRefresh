//
//  UIScrollViewRightRefreshView.swift
//  HBSwiftPublicModule
//
//  Created by HNL on 2022/11/3.
//

import UIKit


@objcMembers
public class UIScrollViewRightRefreshView: UIView, UIScrollViewRightRefreshProtocol {
    public static func right(sideViewWidth: CGFloat) -> UIScrollViewRightRefreshView {
        return UIScrollViewRightRefreshView(frame: CGRect(x: 0, y: 0, width: sideViewWidth, height: UIScreen.main.bounds.size.height))
    }
    public lazy var refreshImage: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        imageView.image = UIImage(named: "1-common_arrow_right_line_24x24")
        return imageView
    }()
    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9)
        label.textColor = UIColor.black
        label.text = self.textDic[.scrollToAction]
        label.numberOfLines = 0
        return label
    }()
    fileprivate var textDic = [DraggingActionText: String]()

    public func setText(_ text: String, mode: DraggingActionText) {
        textDic[mode] = text
        textLabel.text = textDic[.scrollToAction]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.refreshImage)
        self.addSubview(self.textLabel)
        self.backgroundColor = .yellow
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
    }

    public func percentUpdateDuringScrolling(_ percent:CGFloat) {
        if percent > 1.0 {
            guard self.refreshImage.transform == CGAffineTransform.identity else { return }
            UIView.animate(withDuration: 0.4, animations: {
                self.refreshImage.transform = CGAffineTransform(rotationAngle: -CGFloat.pi + 0.000001)
            })
            textLabel.text = textDic[.releaseToAction]
        } else {
            guard self.refreshImage.transform == CGAffineTransform(rotationAngle: -CGFloat.pi + 0.000001) else { return }
            UIView.animate(withDuration: 0.4, animations: {
                self.refreshImage.transform = CGAffineTransform.identity
            })
            textLabel.text = textDic[.scrollToAction]
        }
    }
    
    public func updateContentLocation(draggingDistance: CGFloat) {
        let refreshImageWidth = self.refreshImage.frame.size.width
        self.textLabel.frame = CGRect(origin: CGPoint(x: 2 + refreshImageWidth + 2 + (draggingDistance > 0 ? draggingDistance : 0), y: 0), size: CGSize(width: 9, height: self.frame.size.height))
        self.refreshImage.center = CGPoint(x: 2 + refreshImageWidth / 2 + (draggingDistance > 0 ? draggingDistance : 0), y: self.frame.size.height / 2)
    }

    public func didCompleteRefresh() {
        refreshImage.transform = CGAffineTransform.identity
        textLabel.text = textDic[.scrollToAction]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class RefreshRightContainer: UIView {
    enum RefreshHeaderState {
        case idle
        case pulling
        case refreshing
        case willRefresh
    }

    private var refreshAction: (() -> Void)?
    private var triggerDistance: CGFloat = 0
    private weak var attachedScrollView: UIScrollView?
    // 露出RightRefreshView多少取决于SectionInset Right
    private var rightRefreshViewInsetRight: CGFloat = 0
    private var noRefreshViewInsetRight: CGFloat = 0
    private var isUpdateContentLocationInTheBeginning = false
    private weak var delegate: UIScrollViewRightRefreshProtocol?
    private var state: RefreshHeaderState = .idle {
        didSet {
            guard state != oldValue else { return }
            switch state {
            case .refreshing:
                DispatchQueue.main.async {
                    self.refreshAction?()
                    self.endRefreshing()
                    self.delegate?.didCompleteRefresh()
                }
            default:
                break
            }
        }
    }
    
    init(delegate: UIView & UIScrollViewRightRefreshProtocol,
         noRefreshViewInsetRight: CGFloat,
         rightRefreshViewInsetRight: CGFloat,
         isUpdateContentLocationInTheBeginning: Bool,
         refreshAction: (() -> Void)?) {
        super.init(frame: .zero)
        self.noRefreshViewInsetRight = noRefreshViewInsetRight
        self.rightRefreshViewInsetRight = rightRefreshViewInsetRight
        self.refreshAction = refreshAction
        self.isUpdateContentLocationInTheBeginning = isUpdateContentLocationInTheBeginning
        self.delegate = delegate
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        if self.state == .willRefresh {
            self.state = .refreshing
        }
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            self.handleScrollOffSetChange()
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.removeObservers()
        self.attachedScrollView = nil
        guard let newSuperview = newSuperview as? UIScrollView else { return }
        self.attachedScrollView = newSuperview
        self.attachedScrollView!.addObserver(self, forKeyPath:"contentOffset", options: [.old,.new], context: nil)
        self.attachedScrollView!.addObserver(self, forKeyPath:"contentSize", options:[.old,.new] , context: nil)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard !self.isHidden else { return }
        if keyPath == "contentOffset" {
            handleScrollOffSetChange()
        }
        if keyPath == "contentSize" {
            handleContentSizeChange()
        }
    }
    
    private func handleScrollOffSetChange() {
        guard state != .refreshing, let attachedScrollView = self.attachedScrollView else { return }
        let offSetX = attachedScrollView.contentOffset.x
        let contentSizeWidth = attachedScrollView.contentSize.width
        let scrollViewWidth = attachedScrollView.frame.size.width
        let draggingDistance = offSetX + scrollViewWidth - contentSizeWidth
        if attachedScrollView.isDragging {
            let percent = draggingDistance / triggerDistance
            self.delegate?.percentUpdateDuringScrolling(percent)
            if state == .idle && percent > 1.0 {
                if #available(iOS 13.0, *) {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
                self.state = .pulling
            } else if state == .pulling && percent <= 1.0 {
                state = .idle
            }
        } else if state == .pulling {
            beginRefreshing()
        }
        // 2 + labelWidth + 8 = 19
        self.delegate?.updateContentLocation(draggingDistance: draggingDistance - (self.isUpdateContentLocationInTheBeginning ? 0 : 19))
    }
    
    private func handleContentSizeChange() {
        guard let attachedScrollView = self.attachedScrollView else { return }
        self.isHidden = attachedScrollView.contentSize.width < attachedScrollView.frame.size.width
        if let collectionView = attachedScrollView as? UICollectionView,
           let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset.right = self.isHidden ? self.noRefreshViewInsetRight : self.rightRefreshViewInsetRight
            self.triggerDistance = 72 - (layout.sectionInset.right - layout.minimumLineSpacing)
            self.frame = CGRect(x: attachedScrollView.contentSize.width - (layout.sectionInset.right - layout.minimumLineSpacing), y: layout.sectionInset.top, width: self.frame.size.width, height: self.frame.size.height)
        }
    }

    private func beginRefreshing() {
        if self.window != nil {
            self.state = .refreshing
        } else {
            if state != .refreshing {
                self.state = .willRefresh
            }
        }
    }

    private func endRefreshing() {
        self.state = .idle
    }

    func removeObservers() {
        attachedScrollView?.removeObserver(self, forKeyPath: "contentOffset", context: nil)
        attachedScrollView?.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }

    deinit {
        self.removeObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
