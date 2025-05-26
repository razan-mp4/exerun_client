//
//  WorkoutSyncManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import CoreData
import UIKit
import Network

// ──────────────────────────────────────────────────────────────
// MARK: –  Manager
// ──────────────────────────────────────────────────────────────
final class WorkoutSyncManager {

    // ----------------------------------------------------------
    // Singleton
    // ----------------------------------------------------------
    static let shared = WorkoutSyncManager()         // global instance
    private init() { startReachability() }           // reachability once

    
    private var cancelled = false
    private var pendingTasks = [URLSessionTask]()
    
    func suspend()   { cancelled = true }
    func resume()    { cancelled = false }

    /// Call right after login / app-launch
    func resumeAndPushIfNeeded() {
        resume()
        if hasUnsyncedWorkouts { kick() }
    }
    
    // MARK: – scheduling helpers
    private func add(_ task: URLSessionTask) {
        pendingTasks.append(task)
        task.resume()
    }
    
    // ----------------------------------------------------------
    // Core-Data container
    // ----------------------------------------------------------
    private var container: NSPersistentContainer {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    // ----------------------------------------------------------
    // PUBLIC: start a sync cycle
    // ----------------------------------------------------------
    func kick() {
        DispatchQueue.global(qos: .background).async { self.run() }
    }

    
    // ----------------------------------------------------------
    // PRIVATE: main worker
    // ----------------------------------------------------------
    private func run() {
        if cancelled { return }
        let ctx = container.newBackgroundContext()

        // ► fetch all dirty *or* never-uploaded workouts
        let rq = NSFetchRequest<BaseWorkOutEntity>(entityName: "BaseWorkOutEntity")
        rq.predicate = NSPredicate(format: "remoteID == nil OR isDirty == YES")

        guard let dirty = try? ctx.fetch(rq), dirty.isEmpty == false else { return }

        for w in dirty {
            if w.remoteID == nil {
                uploadNew(w, ctx: ctx)
            } else {
                patchExisting(w, ctx: ctx)           // ← future PATCH logic
            }
        }
    }

    
    // MARK: public helpers ------------------------------------------------------
    var isPullComplete: Bool {
        UserDefaults.standard.bool(forKey: pullDoneKey)
    }

    private func broadcast() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .syncStateChanged, object: nil)
        }
    }
    /// Returns true if there are any workouts with `remoteID == nil` or `isDirty == true`.
    var hasUnsyncedWorkouts: Bool {
        let ctx = container.viewContext
        let rq = NSFetchRequest<NSFetchRequestResult>(entityName: "BaseWorkOutEntity")
        rq.predicate = NSPredicate(format: "remoteID == nil OR isDirty == YES")
        rq.fetchLimit = 1

        do {
            let count = try ctx.count(for: rq)
            return count > 0
        } catch {
            print("⚠️ failed to check unsynced count:", error)
            return false
        }
    }
    
    // MARK: – 1st upload (POST /workouts) ----------------------
    private func uploadNew(_ w: BaseWorkOutEntity, ctx: NSManagedObjectContext) {
        if cancelled { return }
        guard let json = WorkoutUploader.json(from: w) else { return }

        ExerunServerAPIManager.shared.createWorkout(json) { result in
            switch result {

            case .success(let resp):
                ctx.performAndWait {
                    let rq = NSFetchRequest<BaseWorkOutEntity>(entityName: "BaseWorkOutEntity")
                    rq.predicate = NSPredicate(format: "localUUID == %@", resp.local_uuid)
                    rq.fetchLimit = 1
                    if let w = try? ctx.fetch(rq).first {
                        w.remoteID = resp.remote_id
                        w.isDirty  = false
                        try? ctx.save()
                    }
                }
                // picture upload stays unchanged, but pass resp.remote_id
                if let data = (w as? HasImageData)?.imageData {
                    self.uploadImage(data,
                                     for: w.objectID,
                                     remoteID: resp.remote_id)
                }
                self.broadcast()

            case .failure(let err):
                print("❌ upload workout failed:", err)
            }
        }

    }

    // MARK: – future updates (PATCH) ---------------------------
    private func patchExisting(_ w: BaseWorkOutEntity, ctx: NSManagedObjectContext) {
        // TODO: implement PATCH /workouts/{id} when server supports it
        // For now we simply mark it as "clean" so the loop won’t retry forever.
        ctx.performAndWait {
            w.isDirty = false
            try? ctx.save()
            self.broadcast()
        }
    }

    // MARK: – upload JPG after workout is created --------------
    private func uploadImage(_ data: Data,
                             for oid: NSManagedObjectID,
                             remoteID: String) {
        if cancelled { return } 
        ExerunServerAPIManager.shared.uploadWorkoutImage(remoteID: remoteID,
                                             imageData: data) { res in
            switch res {
            case .success(let url):
                let ctx = self.container.newBackgroundContext()
                ctx.performAndWait {
                    if let w = try? ctx.existingObject(with: oid)
                                          as? BaseWorkOutEntity {
                        w.imageURL = url
                        w.isDirty  = false
                        try? ctx.save()
                        self.broadcast()
                    }
                }
            case .failure(let err):
                print("❌ upload picture failed:", err)
            }
        }
    }

    // MARK: – Reachability ------------------------------------
    private let monitor = NWPathMonitor()

    private func startReachability() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.kick()                // network is back → sync!
            }
        }
        let q = DispatchQueue(label: "net.exerun.reachability")
        monitor.start(queue: q)
    }
}

// WorkoutSyncManager.swift  (only the new bits shown)
extension WorkoutSyncManager {

    // PUBLIC – fetch anything newer than lastPull
    func pull(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { self.pullRemote(completion: completion) }
    }


    // keep this somewhere in UserDefaults
    private var lastPullKey: String { "workouts.lastPull" }
    /// written once the first pull finished successfully
    private var pullDoneKey: String { "workouts.pull.done" }

    private func pullRemote(completion: (() -> Void)? = nil) {
        let since = UserDefaults.standard.object(forKey: lastPullKey) as? Date
        ExerunServerAPIManager.shared.listMyWorkouts(since: since) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let remote):
                self.merge(remote)
                UserDefaults.standard.set(Date(), forKey: self.lastPullKey)
                if !UserDefaults.standard.bool(forKey: self.pullDoneKey) {
                    UserDefaults.standard.set(true, forKey: self.pullDoneKey)
                }
                self.broadcast()
                completion?()

            case .failure(let err):
                print("❌ workout download failed:", err)
                completion?()
            }
        }
    }


    // Merge algorithm: insert new, update existing, skip if unchanged
    private func merge(_ remote: [WorkoutResponse]) {
        let ctx = container.newBackgroundContext()
        ctx.performAndWait {

            for r in remote {
                // 1️⃣ find or insert
                let rq = NSFetchRequest<BaseWorkOutEntity>(entityName: "BaseWorkOutEntity")
                rq.predicate = NSPredicate(format:"localUUID == %@ OR remoteID == %@", r.localUUID, r.remoteID)
                rq.fetchLimit = 1
                let local = (try? ctx.fetch(rq))?.first ?? {
                    let name = WorkoutImporter.entityName(for: r.type)!
                    return NSEntityDescription.insertNewObject(forEntityName: name, into: ctx)
                           as! BaseWorkOutEntity
                }()

                // 2️⃣ overwrite fields
                WorkoutImporter.overwrite(local, with: r)

                // 🔧 CRITICAL LINE – make sure the entity is not dirty after pull
                local.isDirty = false
                // 3️⃣ Download image if needed
                if let path = r.imageURL,
                   let target = local as? HasImageData,
                   target.imageData == nil {

                    ExerunServerAPIManager.shared.download(path) { result in
                        if case .success(let data) = result {
                            ctx.performAndWait {
                                target.imageData = data
                                try? ctx.save()
                                self.broadcast()
                            }
                        }
                    }
                }
            }

            do {
                try ctx.save()
            } catch {
                print("❌ Failed to save pulled workouts:", error)
            }
        }
    }


}






// ──────────────────────────────────────────────────────────────
// MARK: –  Core-Data → JSON converter
// ──────────────────────────────────────────────────────────────
enum WorkoutUploader {

    static func json(from w: BaseWorkOutEntity) -> WorkoutUpload? {

        guard let type  = w.type,
              let name  = w.name,
              let date  = w.date else { return nil }

        var duration  = 0              // seconds
        var distance  = 0.0            // km
        var stats: [String:CodableValue] = [:]

        switch w {

        // ────────────── Skiing
        case let ski as SkiingWorkOutEntity:
            duration = Int(ski.avgSpeed > 0 ? ski.distance / ski.avgSpeed * 3600 : 0)
            distance = ski.distance
            stats["max_elevation"]     = .dbl(ski.maxElevation)
            stats["min_elevation"]     = .dbl(ski.minElevation)
            stats["avg_speed_kmh"]     = .dbl(ski.avgSpeed)
            stats["elevation_gain_m"]  = .int(Int(ski.elevationGain))
            stats["max_speed_kmh"]     = .dbl(ski.maxSpeed)
            stats["max_hr"]            = .int(Int(ski.maxHeartRate))
            stats["avg_hr"]            = .int(Int(ski.avarageHeartRate))

        // ────────────── Hiking
        case let hike as HikeWorkOutEntity:
            duration = Int(hike.avgSpeed > 0 ? hike.distance / hike.avgSpeed * 3600 : 0)
            distance = hike.distance
            stats["max_elevation"]     = .dbl(hike.maxElevation)
            stats["min_elevation"]     = .dbl(hike.minElevation)
            stats["avg_speed_kmh"]     = .dbl(hike.avgSpeed)
            stats["elevation_gain_m"]  = .int(Int(hike.elevationGain))
            stats["max_speed_kmh"]     = .dbl(hike.maxSpeed)
            stats["max_hr"]            = .int(Int(hike.maxHeartRate))
            stats["avg_hr"]            = .int(Int(hike.avarageHeartRate))

        // ────────────── Free Run
        case let run as FreeRunWorkOutEntity:
            duration = Int(run.avgSpeed > 0 ? run.distance / run.avgSpeed * 3600 : 0)
            distance = run.distance
            stats["avg_pace"]          = .str(run.avgPace ?? "")
            stats["avg_speed_kmh"]     = .dbl(run.avgSpeed)
            stats["elevation_gain_m"]  = .int(Int(run.elevationGain))
            stats["max_speed_kmh"]     = .dbl(run.maxSpeed)
            stats["max_hr"]            = .int(Int(run.maxHeartRate))
            stats["avg_hr"]            = .int(Int(run.avarageHeartRate))

        // ────────────── Cycling
        case let cyc as CyclingWorkOutEntity:
            duration = Int(cyc.avgSpeed > 0 ? cyc.distance / cyc.avgSpeed * 3600 : 0)
            distance = cyc.distance
            stats["avg_speed_kmh"]     = .dbl(cyc.avgSpeed)
            stats["elevation_gain_m"]  = .int(Int(cyc.elevationGain))
            stats["max_speed_kmh"]     = .dbl(cyc.maxSpeed)
            stats["max_hr"]            = .int(Int(cyc.maxHeartRate))
            stats["avg_hr"]            = .int(Int(cyc.avarageHeartRate))

        // ────────────── Sets-Run (interval run)
        case let sets as SetsRunWorkOutEntity:
            duration = Int(sets.quantity * (sets.workTime + sets.restTime))
            distance = sets.distance
            stats["sets"]              = .int(Int(sets.quantity))
            stats["work_time_s"]       = .int(Int(sets.workTime))
            stats["rest_time_s"]       = .int(Int(sets.restTime))
            stats["avg_pace"]          = .str(sets.avgPace ?? "")
            stats["avg_speed_kmh"]     = .dbl(sets.avgSpeed)
            stats["elevation_gain_m"]  = .int(Int(sets.elevationGain))
            stats["max_speed_kmh"]     = .dbl(sets.maxSpeed)
            stats["max_hr"]            = .int(Int(sets.maxHeartRate))
            stats["avg_hr"]            = .int(Int(sets.avarageHeartRate))

        // ────────────── Quick interval workout
        case let quick as QuickWorkOutEntity:
            duration = Int(quick.quantity * (quick.workTime + quick.restTime))
            stats["sets"]              = .int(Int(quick.quantity))
            stats["work_time_s"]       = .int(Int(quick.workTime))
            stats["rest_time_s"]       = .int(Int(quick.restTime))

        default:
            break
        }

        // segments  (route poly-lines)
        var segs: [[LatLon]]? = nil
        if let blob = (w as? HasSegments)?.segments,
           let obj  = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(blob)
                      as? [[ [String:Double] ]] {

            segs = obj.map { poly in
                poly.map { LatLon(lat: $0["latitude"]!,
                                  lon: $0["longitude"]!) }
            }
        }

        return WorkoutUpload(localUUID   : w.localUUID,
                             type        : type,
                             name        : name,
                             date        : date,
                             duration_s  : duration,
                             distance_km : distance,
                             stats       : stats.isEmpty ? nil : stats,
                             segments    : segs)
    }
}

/// The opposite of WorkoutUploader: writes a WorkoutResponse *into* Core-Data.
enum WorkoutImporter {

    // MARK: – Public entry points
    // ---------------------------------------------------------------------

    /// Insert a new managed object from a server payload.
    static func insert(_ r: WorkoutResponse,
                       into ctx: NSManagedObjectContext)
    {
        guard let entityName = entityName(for: r.type),
              let w = NSEntityDescription.insertNewObject(
                        forEntityName: entityName, into: ctx)
                        as? BaseWorkOutEntity
        else { return }

        w.remoteID = r.remoteID
        overwrite(w, with: r)
    }

    /// Overwrite an existing local workout with fresher data.
    static func overwrite(_ w: BaseWorkOutEntity,
                          with r: WorkoutResponse)
    {
        // ───────────────────────────── generic columns
        w.remoteID = r.remoteID
        w.type      = r.type
        w.name      = r.name
        w.date      = r.date
        w.updatedAt = r.updatedAt
        w.localUUID = r.localUUID
        w.imageURL  = r.imageURL
        w.isDirty   = false               // server = source of truth

        // ───────────────────────────── sport-specific stats
        switch w {

        case let ski as SkiingWorkOutEntity:
            ski.avgSpeed        = dbl(r, "avg_speed_kmh")
            ski.distance        = r.distanceKm
            ski.maxElevation    = dbl(r, "max_elevation")
            ski.minElevation    = dbl(r, "min_elevation")
            ski.elevationGain   = int32(r, "elevation_gain_m")
            ski.maxSpeed        = dbl(r, "max_speed_kmh")
            ski.maxHeartRate    = int32(r, "max_hr")
            ski.avarageHeartRate = int32(r, "avg_hr")

        case let hike as HikeWorkOutEntity:
            hike.avgSpeed       = dbl(r, "avg_speed_kmh")
            hike.distance       = r.distanceKm
            hike.maxElevation   = dbl(r, "max_elevation")
            hike.minElevation   = dbl(r, "min_elevation")
            hike.elevationGain  = int32(r, "elevation_gain_m")
            hike.maxSpeed       = dbl(r, "max_speed_kmh")
            hike.maxHeartRate   = int32(r, "max_hr")
            hike.avarageHeartRate = int32(r, "avg_hr")

        case let run as FreeRunWorkOutEntity:
            run.avgSpeed        = dbl(r, "avg_speed_kmh")
            run.avgPace         = str(r, "avg_pace")
            run.distance        = r.distanceKm
            run.elevationGain   = int32(r, "elevation_gain_m")
            run.maxSpeed        = dbl(r, "max_speed_kmh")
            run.maxHeartRate    = int32(r, "max_hr")
            run.avarageHeartRate = int32(r, "avg_hr")

        case let cyc as CyclingWorkOutEntity:
            cyc.avgSpeed        = dbl(r, "avg_speed_kmh")
            cyc.distance        = r.distanceKm
            cyc.elevationGain   = int32(r, "elevation_gain_m")
            cyc.maxSpeed        = dbl(r, "max_speed_kmh")
            cyc.maxHeartRate    = int32(r, "max_hr")
            cyc.avarageHeartRate = int32(r, "avg_hr")

        case let sets as SetsRunWorkOutEntity:
            sets.quantity       = int32(r, "sets")
            sets.workTime       = int32(r, "work_time_s")
            sets.restTime       = int32(r, "rest_time_s")
            sets.avgPace        = str(r, "avg_pace")
            sets.avgSpeed       = dbl(r, "avg_speed_kmh")
            sets.distance       = r.distanceKm
            sets.elevationGain  = int32(r, "elevation_gain_m")
            sets.maxSpeed       = dbl(r, "max_speed_kmh")
            sets.maxHeartRate   = int32(r, "max_hr")
            sets.avarageHeartRate = int32(r, "avg_hr")

        case let quick as QuickWorkOutEntity:
            quick.quantity      = int32(r, "sets")
            quick.workTime      = int32(r, "work_time_s")
            quick.restTime      = int32(r, "rest_time_s")

        default: break
        }

        // ───────────────────────────── segments (optional)
        if let segs = r.segments,
           let wseg = w as? HasSegments {
            wseg.segments = encodeSegments(segs)
        }
    }

    // MARK: – Helpers
    // ---------------------------------------------------------------------

    static func entityName(for type: String) -> String? {
        switch type.lowercased() {
        case "run":      return "FreeRunWorkOutEntity"
        case "cycling":  return "CyclingWorkOutEntity"
        case "hike":     return "HikeWorkOutEntity"
        case "skiing":   return "SkiingWorkOutEntity"
        case "setsrun":  return "SetsRunWorkOutEntity"
        case "quick":    return "QuickWorkOutEntity"
        default:         return nil
        }
    }

    // Convert poly-lines `[ [LatLon] ]` → Data blob (same format used when saving)
    private static func encodeSegments(_ segs: [[LatLon]]) -> Data? {
        // turn every LatLon → ["latitude": …, "longitude": …]
        let arr = segs.map { poly in
            poly.map { ["latitude": $0.lat, "longitude": $0.lon] }
        }
        return try? NSKeyedArchiver.archivedData(withRootObject: arr,
                                                 requiringSecureCoding: false)
    }
    // Extract helpers ------------------------------------------------------
    private static func int(_ r: WorkoutResponse, _ key: String) -> Double {
        if case .int(let v)? = r.stats?[key] { return Double(v) }
        if case .dbl(let v)? = r.stats?[key] { return v }
        return 0
    }

    private static func dbl(_ r: WorkoutResponse, _ key: String) -> Double {
        if case .dbl(let v)? = r.stats?[key] { return v }
        if case .int(let v)? = r.stats?[key] { return Double(v) }
        return 0
    }

    private static func str(_ r: WorkoutResponse, _ key: String) -> String? {
        if case .str(let s)? = r.stats?[key] { return s }
        return nil
    }
    
    private static func int32(_ r: WorkoutResponse, _ k: String) -> Int32 {
        Int32(int(r, k))
    }
}

extension WorkoutSyncManager {
    func resetPullState() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "workouts.pull.done")
        ud.removeObject(forKey: "workouts.lastPull")
    }
}
