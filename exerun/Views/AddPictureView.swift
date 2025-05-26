//
//  AddPictureView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 14/11/2024.
//

import UIKit

protocol AddPictureViewDelegate: AnyObject {
    func didSelectChooseFromLibrary()
    func didSelectTakePhoto()
}

class AddPictureView: UIView {
    
    weak var delegate: AddPictureViewDelegate?
    
    private var plusLabel: UILabel!
    private var tapToAddLabel: UILabel!
    private var divider: UIView!
    private var chooseFromLibraryLabel: UILabel!
    private var takePhotoLabel: UILabel!
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    private var imageView: UIImageView!
    private var transparentButton: UIButton!
    private var binButton: UIButton! // Bin button to remove the picture
    
    private var initialHeight: CGFloat? // Property to store the initial height
    
    func getImage() -> UIImage? {
        return imageView.image
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitialView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInitialView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if initialHeight == nil {
            initialHeight = self.frame.height
        }
    }
    
    private func setupInitialView() {
        self.backgroundColor = .systemGray4
        self.layer.cornerRadius = 20
        self.isHidden = true
        
        // Image view to display selected picture
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.isHidden = true // Hide initially
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // "+" Label
        plusLabel = UILabel()
        plusLabel.text = "+"
        plusLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        plusLabel.textAlignment = .center
        plusLabel.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        plusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(plusLabel)
        
        // "Tap to add a picture" Label
        tapToAddLabel = UILabel()
        tapToAddLabel.text = "Tap to add a picture"
        tapToAddLabel.font = UIFont.systemFont(ofSize: 14)
        tapToAddLabel.textAlignment = .center
        tapToAddLabel.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        tapToAddLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tapToAddLabel)
        
        NSLayoutConstraint.activate([
            plusLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            plusLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10),
            
            tapToAddLabel.topAnchor.constraint(equalTo: plusLabel.bottomAnchor, constant: 5),
            tapToAddLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
        
        // Transparent button
        transparentButton = UIButton(type: .system)
        transparentButton.backgroundColor = .clear
        transparentButton.translatesAutoresizingMaskIntoConstraints = false
        transparentButton.addTarget(self, action: #selector(addPictureTapped), for: .touchUpInside)
        self.addSubview(transparentButton)
        
        NSLayoutConstraint.activate([
            transparentButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            transparentButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            transparentButton.topAnchor.constraint(equalTo: self.topAnchor),
            transparentButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // Bin button to remove picture
        binButton = UIButton(type: .system)
        binButton.setImage(UIImage(systemName: "trash"), for: .normal)
        binButton.tintColor = UIColor.lightGray
        binButton.backgroundColor = UIColor.systemGray4
        binButton.layer.cornerRadius = 20
        binButton.translatesAutoresizingMaskIntoConstraints = false
        binButton.isHidden = true
        binButton.addTarget(self, action: #selector(removePicture), for: .touchUpInside)
        self.addSubview(binButton)
        
        NSLayoutConstraint.activate([
            binButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            binButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            binButton.widthAnchor.constraint(equalToConstant: 40),
            binButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // Method to set the selected image and show it in the view
    func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        binButton.isHidden = false
        
        // Hide initial elements
        plusLabel.isHidden = true
        tapToAddLabel.isHidden = true
        divider?.isHidden = true
        chooseFromLibraryLabel?.isHidden = true
        takePhotoLabel?.isHidden = true
        leftButton?.isHidden = true
        rightButton?.isHidden = true
        transparentButton.isHidden = true
    }
    
    // Method to remove the image and show the initial state
    @objc private func removePicture() {
        imageView.image = nil
        imageView.isHidden = true
        binButton.isHidden = true
        
        // Show initial elements
        plusLabel.isHidden = false
        tapToAddLabel.isHidden = false
        transparentButton.isHidden = false
    }
    
    @objc private func addPictureTapped() {
        plusLabel.isHidden = true
        tapToAddLabel.isHidden = true
        
        divider = UIView()
        divider.backgroundColor = .lightGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(divider)
        
        NSLayoutConstraint.activate([
            divider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            divider.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            divider.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            divider.widthAnchor.constraint(equalToConstant: 1)
        ])
        
        chooseFromLibraryLabel = UILabel()
        chooseFromLibraryLabel.text = "Choose from Library"
        chooseFromLibraryLabel.font = UIFont.systemFont(ofSize: 14)
        chooseFromLibraryLabel.textAlignment = .center
        chooseFromLibraryLabel.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        chooseFromLibraryLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(chooseFromLibraryLabel)
        
        takePhotoLabel = UILabel()
        takePhotoLabel.text = "Take a Photo"
        takePhotoLabel.font = UIFont.systemFont(ofSize: 14)
        takePhotoLabel.textAlignment = .center
        takePhotoLabel.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        takePhotoLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(takePhotoLabel)
        
        NSLayoutConstraint.activate([
            chooseFromLibraryLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            chooseFromLibraryLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            chooseFromLibraryLabel.trailingAnchor.constraint(equalTo: divider.leadingAnchor, constant: -10),
            
            takePhotoLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            takePhotoLabel.leadingAnchor.constraint(equalTo: divider.trailingAnchor, constant: 10),
            takePhotoLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        ])
        
        setupTappableAreas()
        
        if let initialHeight = initialHeight {
            self.frame.size.height = initialHeight
        }
    }
    
    private func setupTappableAreas() {
        guard let initialHeight = initialHeight else { return }
        
        leftButton = UIButton(type: .system)
        leftButton.backgroundColor = .clear
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.addTarget(self, action: #selector(chooseFromLibraryTapped), for: .touchUpInside)
        self.addSubview(leftButton)
        
        rightButton = UIButton(type: .system)
        rightButton.backgroundColor = .clear
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.addTarget(self, action: #selector(takePhotoTapped), for: .touchUpInside)
        self.addSubview(rightButton)
        
        NSLayoutConstraint.activate([
            leftButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftButton.trailingAnchor.constraint(equalTo: divider.leadingAnchor),
            leftButton.topAnchor.constraint(equalTo: self.topAnchor),
            leftButton.heightAnchor.constraint(equalToConstant: initialHeight),
            
            rightButton.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            rightButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            rightButton.topAnchor.constraint(equalTo: self.topAnchor),
            rightButton.heightAnchor.constraint(equalToConstant: initialHeight)
        ])
    }
    
    @objc private func chooseFromLibraryTapped() {
        delegate?.didSelectChooseFromLibrary()
    }

    @objc private func takePhotoTapped() {
        delegate?.didSelectTakePhoto()
    }
}
