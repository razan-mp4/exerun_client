//
//  BuildCyclingViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//

import UIKit
import CoreLocation

class BuildCyclingViewController: FreeCyclingViewController {
    var route: [CLLocationCoordinate2D] = [] // Route passed from BuiltRouteVC

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the static route on the map
        mapViewContainer.setStaticRoute(route)
    }
}
