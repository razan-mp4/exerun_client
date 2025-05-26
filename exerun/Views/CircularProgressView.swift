//
//  CircularProgressView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/1/2024.
//

import UIKit

class CircularProgressView: UIView {
    
    private var progressLayer: CAShapeLayer!
    
    var progress: CGFloat = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.clear
        
        // Create progress layer
        progressLayer = CAShapeLayer()
        progressLayer.strokeColor = UIColor.systemOrange.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 20.0
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.0
        
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure the circular path is based on the current bounds
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
            radius: bounds.width / 2,
            startAngle: -CGFloat.pi / 2,
            endAngle: 3 * CGFloat.pi / 2,
            clockwise: true
        )
        
        progressLayer.path = circularPath.cgPath
    }
    
    private func updateProgress() {
        progressLayer.strokeEnd = progress
    }
}
