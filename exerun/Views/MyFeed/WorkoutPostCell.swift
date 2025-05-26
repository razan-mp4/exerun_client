//
//  WorkoutPostCell.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/5/2025.
//

import UIKit
import CoreData

/// Table-view cell that embeds a *view* (not VC) showing one workout.
final class WorkoutPostCell: UITableViewCell {

    private var postView: WorkoutPostView?

    /// Call from `cellForRowAt`
    func configure(with id: NSManagedObjectID,
                   onHeightChange: @escaping () -> Void) {

        // remove old
        postView?.removeFromSuperview()

        // build new
        let pv = WorkoutPostView(objectID: id,
                                 heightChanged: onHeightChange)
        pv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pv.topAnchor .constraint(equalTo: contentView.topAnchor),
            pv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        postView = pv
        selectionStyle = .none
    }
}
