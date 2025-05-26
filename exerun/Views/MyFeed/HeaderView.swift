//
//  HeaderView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/5/2025.
//

import UIKit

/// Small bar with profile picture + full name (the same one you already
/// show in `WorkoutHistoryViewController`).
final class HeaderView: UIView {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Avenir-Medium", size: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(nameLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Call from the post-VC
    func configure(with workout: BaseWorkOutEntity) {
        if
            let prof = ProfileStorage.shared.getProfile(),
            let data = prof.imageData,
            let img  = UIImage(data: data) {
            imageView.image = img
        } else {
            imageView.image = UIImage(systemName: "person.circle")
            imageView.tintColor = .systemGray
        }

        if let u = UserStorage.shared.getUser() {
            nameLabel.text = "\(u.name) \(u.surname)"
        }
    }
}
