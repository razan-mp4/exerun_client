//
//  AccountSyncManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 2/5/2025.
//


import UIKit
import CoreData
import Network

/// Handles background sync of **UserEntity** ⤴︎ `/users/me`
/// and **ProfileEntity** ⤴︎ `/profiles/me`
final class AccountSyncManager {

    // ───────────────────────────── Singleton
    static let shared = AccountSyncManager()
    private init() { startReachability() }

    // ───────────────────────────── Container
    private var container: NSPersistentContainer {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    // ───────────────────────────── Public API
    /// Try to upload all dirty user / profile objects in the background.
    func kick() {
        DispatchQueue.global(qos: .background).async { self.run() }
    }

    // ───────────────────────────── Worker
    private func run() {
        guard KeychainManager.shared.loadToken() != nil else { return }

        let ctx = container.newBackgroundContext()

        // 1️⃣  USER
        if let user = fetchDirty(entity: "UserEntity", ctx: ctx) as? UserEntity {
            sync(user, ctx: ctx)
        }

        // 2️⃣  PROFILE
        if let profile = fetchDirty(entity: "ProfileEntity", ctx: ctx) as? ProfileEntity {
            sync(profile, ctx: ctx)
        }
    }

    private func fetchDirty(entity name: String,
                            ctx: NSManagedObjectContext) -> NSManagedObject? {
        let rq = NSFetchRequest<NSManagedObject>(entityName: name)
        rq.predicate = NSPredicate(format: "isDirty == YES")
        rq.fetchLimit = 1
        return try? ctx.fetch(rq).first
    }

    // MARK: – Upload helpers -------------------------------------------------
    private func sync(_ user: UserEntity, ctx: NSManagedObjectContext) {

        ExerunServerAPIManager.shared.updateUser(name: user.name ?? "",
                                     surname: user.surname ?? "") { result in
            switch result {
            case .success:
                ctx.performAndWait {
                    user.isDirty = false
                    try? ctx.save()
                }
                self.broadcast()
            case .failure(let err):
                print("❌ User sync failed:", err)
            }
        }
    }

    private func sync(_ profile: ProfileEntity, ctx: NSManagedObjectContext) {

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale     = Locale(identifier: "en_US_POSIX")
        df.timeZone   = TimeZone(secondsFromGMT: 0)

        // build WeightEntry array only if weight is present
        let weightEntry: [WeightEntry]? = profile.weight > 0
            ? [WeightEntry(date: df.string(from: Date()), value: profile.weight)]
            : nil

        let req = ProfileUpdateRequest(
            height : Int(profile.height),
            weight : weightEntry,
            birthday: profile.birthday.map { df.string(from: $0) },
            gender : profile.gender,
            profile_picture_url: profile.profilePictureURL
        )

        ExerunServerAPIManager.shared.updateProfile(data: req) { result in
            switch result {
            case .success:
                ctx.performAndWait {
                    profile.isDirty = false
                    try? ctx.save()
                }
                self.broadcast()
            case .failure(let err):
                print("❌ Profile sync failed:", err)
            }
        }
    }

    // MARK: – Reachability (reuse pattern)
    private let monitor = NWPathMonitor()

    private func startReachability() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied { self?.kick() }
        }
        monitor.start(queue: .init(label: "net.exerun.account.reachability"))
    }
    
    
    // MARK: – Public helpers
    //-------------------------------------------
    /// `true` if there is *no* User / Profile waiting for upload.
    var hasUnsyncedAccount: Bool {
        let ctx = container.viewContext

        let uRq : NSFetchRequest<NSFetchRequestResult> = UserEntity.fetchRequest()
        uRq.predicate = NSPredicate(format: "isDirty == YES")
        uRq.fetchLimit = 1

        let pRq : NSFetchRequest<NSFetchRequestResult> = ProfileEntity.fetchRequest()
        pRq.predicate = NSPredicate(format: "isDirty == YES")
        pRq.fetchLimit = 1

        return (try? ctx.count(for: uRq)) ?? 0 > 0 ||
               (try? ctx.count(for: pRq)) ?? 0 > 0
    }

    /// Post once every time the dirty / clean state might have changed.
    private func broadcast() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .syncStateChanged, object: nil)
        }
    }
}
