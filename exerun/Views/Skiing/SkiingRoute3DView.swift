//
//  SkiingRoute3DView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/1/2025.
//

import UIKit
import SceneKit
import CoreLocation

final class SkiingRoute3DView: SCNView {
    
    private let sceneRoot = SCNScene()
    private var lastPosition: SCNVector3?
    private var skierNode: SCNNode!
    private var routeSegments: [SCNNode] = []
    
    // Store the first real location as our origin
    private var originLocation: CLLocation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    init() {
        super.init(frame: .zero, options: nil)
        commonInit()
    }
    
    private func commonInit() {
        self.scene = sceneRoot
        self.allowsCameraControl = true
        self.autoenablesDefaultLighting = false
        self.backgroundColor = UIColor.black
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 5000, y: 200, z: 5000)
        cameraNode.camera?.zFar = 100_000
        sceneRoot.rootNode.addChildNode(cameraNode)
        
        // Directional light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.eulerAngles = SCNVector3Make(-.pi/3, .pi/4, 0)
        sceneRoot.rootNode.addChildNode(lightNode)
        
        // Ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        sceneRoot.rootNode.addChildNode(ambientLightNode)
        
        // Create the skier node
        skierNode = createSkierNode()
        sceneRoot.rootNode.addChildNode(skierNode)
    }
    
    /// Updates the skier's 3D position and draws a segment from last position.
    func updateSkierPosition(location: CLLocation) {
        // If we don't have an origin yet, set it to the first location
        if originLocation == nil {
            originLocation = location
        }
        
        let position = coordinateToSCNVector3(location: location)
        print("New 3D position: \(position)")

        if let lastPos = lastPosition {
            let segmentNode = createRouteSegmentNode(from: lastPos, to: position)
            sceneRoot.rootNode.addChildNode(segmentNode)
            routeSegments.append(segmentNode)
        }
        
        // Move the skier
        skierNode.position = position
        lastPosition = position
    }
    
    private func coordinateToSCNVector3(location: CLLocation) -> SCNVector3 {
        guard let origin = originLocation else {
            return SCNVector3Zero
        }
        
        let metersPerDegreeLat: Double = 111_000
        let scaleFactor: Float =  0.01
        
        // differences from origin
        let deltaLat  = Float(location.coordinate.latitude  - origin.coordinate.latitude)
        let deltaLong = Float(location.coordinate.longitude - origin.coordinate.longitude)
        let latMeters = deltaLat  * Float(metersPerDegreeLat)
        let lonMeters = deltaLong * Float(metersPerDegreeLat)
                          * cosf(Float(origin.coordinate.latitude) * .pi / 180)
        
        let xPos = lonMeters * scaleFactor
        let zPos = -latMeters * scaleFactor
        
        let altDelta = Float(location.altitude - origin.altitude)
        let yPos = altDelta * 0.5  // scale altitude if desired
        
        return SCNVector3(x: xPos, y: yPos, z: zPos)
    }
    
    private func createSkierNode() -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    private func createRouteSegmentNode(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let segmentVector = SCNVector3(to.x - from.x, to.y - from.y, to.z - from.z)
        let distance = length(of: segmentVector)
        print("Segment distance:", distance)
        let midPoint = SCNVector3((from.x + to.x) / 2.0,
                                  (from.y + to.y) / 2.0,
                                  (from.z + to.z) / 2.0)
        
        let cylinder = SCNCylinder(radius: 0.2, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor.cyan
        let segmentNode = SCNNode(geometry: cylinder)
        segmentNode.position = midPoint
        segmentNode.eulerAngles = cylinderEulerAngles(for: segmentVector)
        
        return segmentNode
    }
    
    private func length(of v: SCNVector3) -> Float {
        return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z)
    }
    
    private func cylinderEulerAngles(for vector: SCNVector3) -> SCNVector3 {
        let xyDist = sqrt(vector.x * vector.x + vector.z * vector.z)
        let heightAngle = atan2(xyDist, vector.y)
        let heading = atan2(vector.x, vector.z)
        
        let pitch = .pi/2 - heightAngle
        return SCNVector3(pitch, heading, 0)
    }
    
    /// If you want to remove all segments and reset
    func clearRoute() {
        for segment in routeSegments {
            segment.removeFromParentNode()
        }
        routeSegments.removeAll()
        lastPosition = nil
        originLocation = nil
        // Reset the skier node back to origin
        skierNode.position = SCNVector3Zero
    }
}
