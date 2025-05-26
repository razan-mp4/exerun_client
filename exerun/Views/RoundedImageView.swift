//
//  RoundedImageView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/8/2024.
//

import UIKit

class RoundedImageView: UIView {
    
    private let imageView = UIImageView()
    private let overlayView = UIView()

    // Initializer for using in code
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    // Initializer for using in Interface Builder
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Add image view to the view
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Configure image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10 // Adjust as needed
        
        // Add overlay view for darkening effect
        addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Configure overlay view
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Adjust the alpha for darkness level
        overlayView.layer.cornerRadius = 10 // Match the corner radius
        overlayView.clipsToBounds = true
    }
    
    // Function to set image
    func setImage(_ image: UIImage) {
        imageView.image = image
    }
    
    // Function to adjust corner radius
    func setCornerRadius(_ radius: CGFloat) {
        imageView.layer.cornerRadius = radius
        overlayView.layer.cornerRadius = radius
    }
    
    // Function to adjust darkness
    func setDarkness(alpha: CGFloat) {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
    }
}
