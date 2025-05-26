//
//  Constants.swift
//  exerun
//
//  Created by Nazar Odemchuk on 4/5/2025.
//

import Foundation

extension Notification.Name {
    /// Fired by *both* sync managers whenever their state changes
    static let syncStateChanged = Notification.Name("net.exerun.syncStateChanged")
}
