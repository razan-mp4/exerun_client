//
//  BuildRunViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 11/8/2024.
//

import UIKit
import CoreLocation

class BuildRunViewController: FreeRunViewController {
    var route: [CLLocationCoordinate2D] = [] // Route passed from BuiltRouteVC

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the static route on the map
        mapViewContainer.setStaticRoute(route)
    }
}
