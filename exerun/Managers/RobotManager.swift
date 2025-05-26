//
//  RobotManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/4/2025.
//


import RealityKit
import Combine
import Foundation

final class RobotManager {
    static let shared = RobotManager()
    private init() {}

    private var cache: [String: Entity] = [:]
    private var cancellables = Set<AnyCancellable>()

    // ───────────────────────── Async (unchanged)
    func load(named filename: String, completion: @escaping (Entity?) -> Void) {
        if let cached = cache[filename] {
            completion(cached.clone(recursive: true))
            return
        }
        Entity.loadAsync(named: filename)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] entity in
                      self?.cache[filename] = entity
                      completion(entity.clone(recursive: true))
                  })
            .store(in: &cancellables)
    }

    // ───────────────────────── NEW — synchronous preload
    /// **Blocks** the current thread until the USD is fully loaded *and*
    /// `applyInitialMaterial` has run.  Call from a background queue *or*
    /// during app-launch before the first run loop tick.
    func preloadSync(named filename: String) {
        guard cache[filename] == nil else { return }

        // 1) Raw entity
        guard let entity = try? Entity.load(named: filename) else { return }

        // 2) Attach the default PBR material once, so every future clone
        //    already has textured meshes.
        applyInitialMaterial(to: entity)

        cache[filename] = entity
    }

    // MARK: – material helper moved here so we can reuse it
    private func applyInitialMaterial(to root: Entity) {
        guard
            let albedo   = try? TextureResource.load(named: "Sad_Old_Robot_base.png"),
            let normal   = try? TextureResource.load(named: "Sad_Old_Robot_normal.png"),
            let rough    = try? TextureResource.load(named: "Sad_Old_Robot_roughness.png"),
            let emissive = try? TextureResource.load(named: "Sad_Old_Robot_emit.png")
        else { print("⚠️ missing textures"); return }

        var mat = PhysicallyBasedMaterial()
        mat.baseColor.texture      = .init(albedo)
        mat.normal.texture         = .init(normal)
        mat.roughness.texture      = .init(rough)
        mat.emissiveColor.texture  = .init(emissive)
        mat.emissiveIntensity      = 2

        root.visit { ($0 as? ModelEntity)?.model?.materials = [mat] }
    }
}

extension Entity {
    /// Depth-first visitor used across the app.
    func visit(_ body: (Entity) -> Void) {
        body(self)
        children.forEach { $0.visit(body) }
    }
}

enum RobotEnvironment {
    static let sharedRobotView: RobotView = {
        let v = RobotView()
        v.configure(file: "robot.usdc")   // done only once
        return v
    }()
}
