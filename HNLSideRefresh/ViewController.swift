//
//  ViewController.swift
//  HNLSideRefresh
//
//  Created by HNL on 2022/11/26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(collectionView)
        let right = UIScrollViewRightRefreshView.right(sideViewWidth: 200)
        right.setText("左滑查看更多", mode: .scrollToAction)
        right.setText("松开查看更多", mode: .releaseToAction)
        self.collectionView.configRightSideRefresh(with: right,
                                                   sideViewHeight: 100,
                                                   isUpdateContentLocationInTheBeginning: true,
                                                   noRefreshViewInsetRight: 12,
                                                   rightRefreshViewInsetRight: 43) {
            print(123)
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 10
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 100)
, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "123")
        return collectionView
    }()
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 59)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 6 }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "123", for: indexPath)
        cell.contentView.backgroundColor = .gray
        return cell
    }
}

