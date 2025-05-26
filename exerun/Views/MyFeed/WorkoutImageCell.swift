//
//  WorkoutImageCell.swift
//  exerun
//
//  Created by Nazar Odemchuk on 4/5/2025.
//

import UIKit

final class WorkoutImageCell: UICollectionViewCell {

    static let reuseID = "WorkoutImageCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with image: UIImage?) {
        if let img = image {
            imageView.image = img
            imageView.backgroundColor = .clear
        } else {
            imageView.image = nil
            imageView.backgroundColor = .secondarySystemBackground
        }
    }
}
