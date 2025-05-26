//
//  WorkoutPostViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/5/2025.
//

import UIKit
import CoreData
import MapKit

final class WorkoutPostView: UIView {

    // MARK: – Model
    private let workout: BaseWorkOutEntity
    private let media  : [UIImage]
    private var statsExpanded = false
    private let heightChanged: () -> Void     // callback to resize the cell

    // MARK: – Subviews
    private let header = HeaderView()
    private lazy var mediaPager = MediaPager(images: media)
    private let captionLabel = UILabel()
    private let moreButton   = UIButton(type: .system)
    private let statsStack   = UIStackView()
    private let separator    = UIView()

    // MARK: – Init
    init(objectID: NSManagedObjectID,
         heightChanged: @escaping () -> Void) {

        let ctx = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
        self.workout = try! ctx.existingObject(with: objectID) as! BaseWorkOutEntity
        self.media   = WorkoutPostView.collectMedia(from: workout)
        self.heightChanged = heightChanged
        super.init(frame: .zero)
        setup()
        populate()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: – Layout
    private func setup() {
        [header, mediaPager, captionLabel, moreButton, statsStack, separator]
            .forEach { v in addSubview(v); v.translatesAutoresizingMaskIntoConstraints = false }

        // header
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            header.heightAnchor.constraint(equalToConstant: 44)
        ])

        // media (square)
        NSLayoutConstraint.activate([
            mediaPager.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            mediaPager.leadingAnchor.constraint(equalTo: leadingAnchor),
            mediaPager.trailingAnchor.constraint(equalTo: trailingAnchor),
            mediaPager.widthAnchor.constraint(equalTo: mediaPager.heightAnchor)
        ])

        // caption
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: mediaPager.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        // more button
        moreButton.setTitle("More", for: .normal)
        moreButton.setTitleColor(.systemOrange, for: .normal)
        moreButton.addTarget(self, action: #selector(toggleStats), for: .touchUpInside)
        NSLayoutConstraint.activate([
            moreButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            moreButton.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor)
        ])

        // stats
        statsStack.axis = .vertical
        statsStack.spacing = 2
        statsStack.isHidden = true
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: moreButton.bottomAnchor, constant: 4),
            statsStack.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: captionLabel.trailingAnchor)
        ])

        // separator
        separator.backgroundColor = .systemGray5
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: – Content
    private func populate() {

        header.configure(with: workout)

        // Caption
        let df = DateFormatter(); df.dateStyle = .medium
        let name = workout.name ?? "Workout"
        let type = workout.type ?? "-"
        let date = workout.date.map { df.string(from: $0) } ?? "–"
        captionLabel.font = UIFont(name: "Avenir-Medium", size: 16)
        captionLabel.text = "\(name) • \(type) • \(date)"

        // clear stats
        statsStack.arrangedSubviews.forEach {
            statsStack.removeArrangedSubview($0); $0.removeFromSuperview()
        }

        // helpers
        func add(_ key: String, _ txt: String?) {
            guard let v = txt, !v.isEmpty else { return }
            statsStack.addArrangedSubview(makeStat(key, v))
        }
        func fmt(_ d: Double, _ f: String) -> String { String(format: f, d) }

        // generic (avoid duplicates later)
        let isInterval = workout is SetsRunWorkOutEntity || workout is QuickWorkOutEntity
        if let d = workout.double("distance") { add("Distance", fmt(d, "%.2f km")) }
        if !isInterval {
            if let w = workout.int32("workTime") { add("Work time", "\(w) s") }
            if let r = workout.int32("restTime") { add("Rest time", "\(r) s") }
            if let q = workout.int32("quantity") { add("Sets", "\(q)") }
        }

        // per-sport
        switch workout {

        case let run as FreeRunWorkOutEntity:
            add("Avg pace",  run.avgPace)
            add("Avg speed", fmt(run.avgSpeed, "%.1f km/h"))
            add("Max speed", fmt(run.maxSpeed, "%.1f km/h"))
            add("Elev. gain", "\(run.elevationGain) m")
            add("Avg HR",    "\(run.avarageHeartRate) bpm")
            add("Max HR",    "\(run.maxHeartRate) bpm")

        case let cyc as CyclingWorkOutEntity:
            add("Avg pace",  cyc.avgPace)
            add("Avg speed", fmt(cyc.avgSpeed, "%.1f km/h"))
            add("Max speed", fmt(cyc.maxSpeed, "%.1f km/h"))
            add("Elev. gain", "\(cyc.elevationGain) m")
            add("Avg HR",    "\(cyc.avarageHeartRate) bpm")
            add("Max HR",    "\(cyc.maxHeartRate) bpm")

        case let hike as HikeWorkOutEntity:
            add("Avg pace",  hike.avgPace)
            add("Avg speed", fmt(hike.avgSpeed, "%.1f km/h"))
            add("Max speed", fmt(hike.maxSpeed, "%.1f km/h"))
            add("Elev. gain", "\(hike.elevationGain) m")
            add("Min elev.", fmt(hike.minElevation, "%.0f m"))
            add("Max elev.", fmt(hike.maxElevation, "%.0f m"))
            add("Avg HR",    "\(hike.avarageHeartRate) bpm")
            add("Max HR",    "\(hike.maxHeartRate) bpm")

        case let ski as SkiingWorkOutEntity:
            add("Avg pace",  ski.avgPace)
            add("Avg speed", fmt(ski.avgSpeed, "%.1f km/h"))
            add("Max speed", fmt(ski.maxSpeed, "%.1f km/h"))
            add("Elev. gain", "\(ski.elevationGain) m")
            add("Min elev.", fmt(ski.minElevation, "%.0f m"))
            add("Max elev.", fmt(ski.maxElevation, "%.0f m"))
            add("Avg HR",    "\(ski.avarageHeartRate) bpm")
            add("Max HR",    "\(ski.maxHeartRate) bpm")

        case let sets as SetsRunWorkOutEntity:
            add("Sets",      "\(sets.quantity)")
            add("Work time", "\(sets.workTime) s")
            add("Rest time", "\(sets.restTime) s")
            add("Avg pace",  sets.avgPace)
            add("Avg speed", fmt(sets.avgSpeed, "%.1f km/h"))
            add("Max speed", fmt(sets.maxSpeed, "%.1f km/h"))

        case let quick as QuickWorkOutEntity:
            add("Sets",      "\(quick.quantity)")
            add("Work time", "\(quick.workTime) s")
            add("Rest time", "\(quick.restTime) s")

        default: break
        }
    }

    // MARK: –
    private func makeStat(_ key: String, _ value: String) -> UIView {
        let lbl = UILabel()
        lbl.font = UIFont(name: "Avenir", size: 14)
        lbl.text = "\(key): \(value)"
        return lbl
    }

    @objc private func toggleStats() {
        statsExpanded.toggle()
        statsStack.isHidden = !statsExpanded
        moreButton.setTitle(statsExpanded ? "Less" : "More", for: .normal)
        heightChanged()                       // tell the table to re-layout
    }
}

// MARK: – Collect media (photo + optional route)
private extension WorkoutPostView {
    static func collectMedia(from w: BaseWorkOutEntity) -> [UIImage] {
        var arr: [UIImage] = []
        if let h = w as? HasImageData,
           let d = h.imageData, let img = UIImage(data: d) { arr.append(img) }

        if let s = w as? HasSegments,
           let d = s.segments,
           let snap = MapSnapshotter.snapshot(for: d) { arr.append(snap) }
        return arr
    }
}


// ──────────────────────────────────────────────────────────────
// MARK: – Map snapshot for route overlay
// ──────────────────────────────────────────────────────────────
import UIKit
import MapKit

enum MapSnapshotter {

    // MARK: – Public: synchronous helper (but non-blocking!)
    static func snapshot(for data: Data) -> UIImage? {

        // 1. Decode   [[[ "latitude":Double , "longitude":Double ]]]
        guard
            let raw = try? NSKeyedUnarchiver
                .unarchiveTopLevelObjectWithData(data) as? [[ [String: Double] ]],
            !raw.isEmpty
        else { return nil }

        // 2. Flatten & validate coordinates
        let coords = raw
            .flatMap { $0 }
            .compactMap { dict -> CLLocationCoordinate2D? in
                guard
                    let lat = dict["latitude"],  (-90 ...  90).contains(lat),
                    let lon = dict["longitude"], (-180 ... 180).contains(lon)
                else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }

        guard coords.count >= 2 else { return nil }          // need a line

        // 3. Visible map rect (+20 % padding)
        var rect = MKPolyline(coordinates: coords, count: coords.count)
                    .boundingMapRect
        rect = rect.insetBy(dx: -rect.width  * 0.2,
                            dy: -rect.height * 0.2)

        // 4. Options
        let opts       = MKMapSnapshotter.Options()
        opts.mapRect   = rect
        opts.size      = CGSize(width: 512, height: 512)
        opts.scale     = UIScreen.main.scale

        // 5. Take snapshot on a **background** queue so the main thread
        //    can safely wait without dead-locking.
        guard let snap = syncSnapshot(opts, queue: .global(qos: .userInitiated))
        else { return nil }

        // 6. Draw poly-line over snapshot
        UIGraphicsBeginImageContextWithOptions(opts.size, true, 0)
        snap.image.draw(at: .zero)

        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setLineWidth(4)
        ctx.setStrokeColor(UIColor.systemOrange.cgColor)

        let points = coords.map { snap.point(for: $0) }
        ctx.move(to: points.first!)
        points.dropFirst().forEach { ctx.addLine(to: $0) }
        ctx.strokePath()

        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: – Private
    private static func syncSnapshot(
        _ opts: MKMapSnapshotter.Options,
        queue: DispatchQueue
    ) -> MKMapSnapshotter.Snapshot? {

        let snapper = MKMapSnapshotter(options: opts)
        var result : MKMapSnapshotter.Snapshot?
        let sema   = DispatchSemaphore(value: 0)

        snapper.start(with: queue) { snap, _ in
            result = snap
            sema.signal()
        }
        sema.wait()                    // waits on **main**, completion on *queue*
        return result
    }
}


// ──────────────────────────────────────────────────────────────
// MARK: – Core-Data convenience
// ──────────────────────────────────────────────────────────────
private extension NSManagedObject {

    /// Does this entity have such attribute?
    func hasAttribute(_ name: String) -> Bool {
        entity.attributesByName.keys.contains(name)
    }

    func int32(_ name: String) -> Int32?  {
        hasAttribute(name) ? value(forKey: name) as? Int32 : nil
    }
    func double(_ name: String) -> Double? {
        hasAttribute(name) ? value(forKey: name) as? Double : nil
    }
}

/// Generic distances / work-times for quick display
extension BaseWorkOutEntity {
    var distanceValue: Double? { double("distance") }
    var workTimeValue: Int32?  { int32 ("workTime") }
}
