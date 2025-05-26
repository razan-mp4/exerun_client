//
//  MediaPager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/5/2025.
//

import UIKit

final class MediaPager: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let images: [UIImage]
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate   = self
        cv.register(Cell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }()
    private let pager = UIPageControl()

    init(images: [UIImage]) {
        self.images = images
        super.init(frame: .zero)
        addSubview(collection)
        addSubview(pager)
        collection.translatesAutoresizingMaskIntoConstraints = false
        pager.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: topAnchor),
            collection.leadingAnchor.constraint(equalTo: leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: bottomAnchor),

            pager.centerXAnchor.constraint(equalTo: centerXAnchor),
            pager.bottomAnchor .constraint(equalTo: bottomAnchor, constant: -8)
        ])
        pager.numberOfPages = images.count
        pager.currentPage = 0
    }
    required init?(coder: NSCoder) { fatalError() }

    // -- Collection DS
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        cv.bounds.size          // full-width paging
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pager.currentPage = page
    }

    private class Cell: UICollectionViewCell {
        let imageView = UIImageView(frame: .zero)
        override init(frame: CGRect) {
            super.init(frame: frame)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        required init?(coder: NSCoder) { fatalError() }
    }
}
