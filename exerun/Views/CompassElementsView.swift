//
//  CompassElementsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 27/1/2025.
//

import UIKit

class CompassElementsView: UIView {
    private let tickCount = 36
    private let tickLength: CGFloat = 10
    private let tickWidth: CGFloat = 2
    private let arrowSize: CGFloat
    private var compassArrowLayer: CAShapeLayer!
    private var textColor: UIColor = .white // Default to white for dark mode
    private var currentHeading: CGFloat = 0 // Heading in radians to rotate the elements

    init(arrowSize: CGFloat) {
        self.arrowSize = arrowSize
        super.init(frame: .zero)
        setupArrowLayer()
    }
    
    override init(frame: CGRect) {
        self.arrowSize = 100 // Provide a default value
        super.init(frame: frame)
        textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        setupArrowLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupArrowLayer() {
        // Create the pointing triangle (orange)
        let pointingTriangleLayer = CAShapeLayer()
        let pointingTrianglePath = UIBezierPath()
        pointingTrianglePath.move(to: CGPoint(x: 0, y: -arrowSize / 2)) // Tip
        pointingTrianglePath.addLine(to: CGPoint(x: -arrowSize / 12, y: 0)) // Bottom left
        pointingTrianglePath.addLine(to: CGPoint(x: arrowSize / 12, y: 0)) // Bottom right
        pointingTrianglePath.close()

        pointingTriangleLayer.path = pointingTrianglePath.cgPath
        pointingTriangleLayer.fillColor = UIColor.systemOrange.cgColor

        // Create the back triangle (grey)
        let backTriangleLayer = CAShapeLayer()
        let backTrianglePath = UIBezierPath()
        backTrianglePath.move(to: CGPoint(x: 0, y: arrowSize / 2)) // Bottom tip
        backTrianglePath.addLine(to: CGPoint(x: -arrowSize / 12, y: 0)) // Top left
        backTrianglePath.addLine(to: CGPoint(x: arrowSize / 12, y: 0)) // Top right
        backTrianglePath.close()

        backTriangleLayer.path = backTrianglePath.cgPath
        backTriangleLayer.fillColor = UIColor.systemGray.cgColor

        // Combine both layers into the compass arrow layer
        compassArrowLayer = CAShapeLayer()
        compassArrowLayer.addSublayer(backTriangleLayer)
        compassArrowLayer.addSublayer(pointingTriangleLayer)

        // Set the anchor point and position
        compassArrowLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        compassArrowLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        // Add the arrow layer to the view's layer
        layer.addSublayer(compassArrowLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        compassArrowLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func updateTickMarkColors(for isDarkMode: Bool) {
        textColor = isDarkMode ? .white : .black // Update text color based on mode
        setNeedsDisplay() // Redraw the tick marks and labels with the updated color
    }

    func updateArrowRotation(radians: CGFloat) {
        // Update the current heading (rotation for the drawn elements)
        currentHeading = radians
        setNeedsDisplay() // Redraw the view with the updated rotation
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let radius = (rect.width / 2) - 40 // Adjust this value for padding
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let angles: [CGFloat] = [0, .pi / 4, .pi / 2, 3 * .pi / 4, .pi, 5 * .pi / 4, 3 * .pi / 2, 7 * .pi / 4]
        let degrees = stride(from: 0, through: 330, by: 30).map { $0 }
        let fontPrimary = UIFont(name: "Avenir", size: 16)! // Larger font for main directions
        let fontSecondary = UIFont(name: "Avenir", size: 12)! // Smaller font for secondary directions
        let fontDegrees = UIFont(name: "Avenir", size: 14)!
        let labelInsetFactor: CGFloat = 6
        let degreeInsetFactor: CGFloat = -2

        let tickColor: UIColor = textColor.withAlphaComponent(0.5)

        context.saveGState()
        context.translateBy(x: center.x, y: center.y) // Move context to center
        context.rotate(by: currentHeading) // Rotate context by heading to simulate rotation

        // Draw tick marks
        for i in 0..<tickCount {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(tickCount))
            let xStart = radius * cos(angle)
            let yStart = radius * sin(angle)
            let xEnd = (radius - tickLength) * cos(angle)
            let yEnd = (radius - tickLength) * sin(angle)
            
            context.move(to: CGPoint(x: xStart, y: yStart))
            context.addLine(to: CGPoint(x: xEnd, y: yEnd))
            context.setStrokeColor(tickColor.cgColor)
            context.setLineWidth(tickWidth)
            context.strokePath()
        }

        context.restoreGState() // Restore context after rotating tick marks

        // Place cardinal directions
        for (index, direction) in directions.enumerated() {
            let angle = angles[index] - (.pi / 2) - currentHeading // Adjust angle to keep text readable
            let font = (direction.count == 1) ? fontPrimary : fontSecondary // Use primary font for "N", "E", "S", "W"
            let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            let textSize = direction.size(withAttributes: textAttributes)
            
            let textX = center.x + (radius - tickLength * labelInsetFactor) * cos(angle) - textSize.width / 2
            let textY = center.y + (radius - tickLength * labelInsetFactor) * sin(angle) - textSize.height / 2
            
            direction.draw(at: CGPoint(x: textX, y: textY), withAttributes: textAttributes)
        }

        // Place degrees
        for (index, degree) in degrees.enumerated() {
            let angle = CGFloat(index) * (2 * .pi / CGFloat(degrees.count)) - (.pi / 2) - currentHeading
            let text = "\(degree)°"
            let textAttributes: [NSAttributedString.Key: Any] = [.font: fontDegrees, .foregroundColor: textColor]
            let textSize = text.size(withAttributes: textAttributes)
            
            let textX = center.x + (radius - tickLength * degreeInsetFactor) * cos(angle) - textSize.width / 2
            let textY = center.y + (radius - tickLength * degreeInsetFactor) * sin(angle) - textSize.height / 2
            
            text.draw(at: CGPoint(x: textX, y: textY), withAttributes: textAttributes)
        }
    }

}
