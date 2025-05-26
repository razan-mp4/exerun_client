//
//  RobotView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/4/2025.
//


import UIKit
import RealityKit
import Combine                      // for Cancellable
import AVFoundation

/// Adopt this in a view-controller that shows the robot
protocol RobotHelpProvider: AnyObject {
    /// Sentences the robot should speak when Help is tapped.
    /// Return an empty array if no help is needed on this screen.
    func robotHelpScript() -> [String]
}

final class RobotView: UIView {

    var lastUsedHeight: CGFloat = 300  
    
    // ───────────────────────── Scene graph
    private let rkView: ARView = {
        let v = ARView(frame: .zero,
                       cameraMode: .nonAR,
                       automaticallyConfigureSession: false)
        v.environment.background = .color(.clear)
        return v
    }()

    private let sceneAnchor = AnchorEntity()    // camera + light (never rotates)
    private let spinAnchor  = AnchorEntity()    // holds robot; we rotate this
    private weak var muteButton: UIButton?

    private weak var helpButton: UIButton?          // ←  needed for enable/disable
    weak var helpProvider: RobotHelpProvider?       // ←  set by each VC
    private var helpIsLocked = false                // ←  true while talking

    
    private var robotEntity: Entity?

    // snap-back state
    private var restoreTimer: Timer?
    private var resetAnim: Cancellable?

    // ───────────────────────── Init / layout
    override init(frame: CGRect)  { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        rkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rkView)
        NSLayoutConstraint.activate([
            rkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rkView.topAnchor.constraint(equalTo: topAnchor),
            rkView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        isUserInteractionEnabled = true
        backgroundColor = .clear

        // ① camera
        let cam = PerspectiveCamera()
        cam.position = [0, 0, 1]                           // 1 m in front
        cam.look(at: .zero, from: cam.position, relativeTo: nil)
        sceneAnchor.addChild(cam)

        // ② light
        let sun = DirectionalLight()
        sun.light.intensity = 1_000
        sun.orientation = simd_quatf(angle: .pi/4, axis: [1,0,0])
        sceneAnchor.addChild(sun)

        // anchors
        rkView.scene.anchors.append(sceneAnchor)
        rkView.scene.anchors.append(spinAnchor)

        // ③ pan gesture
        rkView.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        
        addSideButtons()
    }

    // ───────────────────────── Public API
    func configure(file filename: String,
                   clipName: String = "global scene animation") {

        RobotManager.shared.load(named: filename) { [weak self] model in
            guard let self, let model else { return }

            self.robotEntity?.removeFromParent()
            self.robotEntity = model

            model.scale    = SIMD3<Float>(repeating: 7.0)
            model.position = [0, -0.4, 0]
            self.applyRobotMaterial(to: model)

            self.spinAnchor.children.removeAll()
            self.spinAnchor.addChild(model)
            self.loop(clipNamed: clipName)
        }
    }

    // ───────────────────────── Gesture + inactivity timer
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {

        // rotate while dragging
        let dx = Float(g.translation(in: rkView).x) * 0.005
        spinAnchor.orientation *= simd_quatf(angle: dx, axis: [0,1,0])
        g.setTranslation(.zero, in: rkView)

        // cancel any pending reset
        restoreTimer?.invalidate(); restoreTimer = nil
        resetAnim?.cancel();        resetAnim    = nil

        // start 3-s countdown when finger lifts
        if g.state == .ended || g.state == .cancelled {
            restoreTimer = Timer.scheduledTimer(withTimeInterval: 2.0,
                                                repeats: false) { [weak self] _ in
                self?.animateBackToFront()
            }
        }
    }

    /// Smoothly interpolate orientation back to identity over 0.4 s
    private func animateBackToFront() {
        let start = spinAnchor.orientation
        let end   = simd_quatf(angle: 0, axis: [0,1,0])

        var t: Float = 0
        resetAnim = rkView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] ev in
            guard let self else { return }
            t += Float(ev.deltaTime) / 0.4            // 0.4 s duration
            if t >= 1 {
                self.spinAnchor.orientation = end
                self.resetAnim?.cancel(); self.resetAnim = nil
            } else {
                self.spinAnchor.orientation = simd_slerp(start, end, t)
            }
        }
    }

    // ───────────────────────── Material helper
    private func applyRobotMaterial(to root: Entity) {
        guard
            let albedo   = try? TextureResource.load(named: "Sad_Old_Robot_base.png"),
            let normal   = try? TextureResource.load(named: "Sad_Old_Robot_normal.png"),
            let rough    = try? TextureResource.load(named: "Sad_Old_Robot_roughness.png"),
            let emissive = try? TextureResource.load(named: "Sad_Old_Robot_emit.png")
        else { print("⚠️ Missing texture PNGs"); return }

        var mat = PhysicallyBasedMaterial()
        mat.baseColor.texture      = .init(albedo)
        mat.normal.texture         = .init(normal)
        mat.roughness.texture      = .init(rough)
        mat.emissiveColor.texture  = .init(emissive)
        mat.emissiveIntensity      = 2

        root.visit { ($0 as? ModelEntity)?.model?.materials = [mat] }
    }

    // ───────────────────────── Clip loop
    private func loop(clipNamed name: String) {
        guard
            let ent  = robotEntity,
            let clip = ent.availableAnimations.first(where: { $0.name == name })
        else { return }

        ent.stopAllAnimations()
        ent.playAnimation(clip.repeat(),
                          transitionDuration: 0.264,
                          startsPaused: false)
    }
}


// MARK: – Talking helper
private struct RobotRestState {
    let scale: SIMD3<Float>
    let position: SIMD3<Float>
}


private var bubbleIsBusy = false      // typing or waiting


extension RobotView {

    // MARK: public API
    
    /// First preferred language (e.g. "uk-UA") or "en-US" as a safe default
    private var defaultVoiceLanguage: String {
        let preferred = Locale.preferredLanguages.first ?? "en-US"
        // Ensure the language is supported by AVSpeechSynthesisVoice
        if AVSpeechSynthesisVoice(language: preferred) != nil {
            return preferred
        } else if preferred.starts(with: "uk") {
            return "uk-UA" // Ukrainian
        } else {
            return "en-US" // Fallback to English
        }
    }



    /// Queues a message for the robot to “speak” (bubble + Siri voice).
    private static func availableVoiceLanguage() -> String {
        let currentLang = LocalizationManager.shared.currentLanguage

        if currentLang.starts(with: "uk") {
            return "uk-UA" // Ukrainian Siri voice (if available)
        } else if currentLang.starts(with: "en") {
            return "en-US" // English Siri voice
        } else {
            return "en-US" // fallback to English if unknown
        }
    }

    func speak(_ text: String,
               autoHide: TimeInterval = 2.5,
               typingSpeed: TimeInterval = 0.07,
               voiceLanguage: String? = nil)
    {
        let lang = voiceLanguage ?? RobotView.availableVoiceLanguage()

        speechQueue.append(.init(text: text,
                                  autoHide: autoHide,
                                  typing: typingSpeed,
                                  lang: lang))

        if !bubbleIsBusy {
            dequeueAndShowNext()
        }
    }


    /// Immediately stops voice & bubble, clears queue, re-enables Help.
    func stopSpeaking() {
        Self.ttsSynth.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        subviews.first(where: { $0 is SpeechBubbleView })?.removeFromSuperview()
        bubbleIsBusy  = false
        helpIsLocked  = false
        updateHelpButton(enabled: true)
        restoreRobotIfNeeded()
    }

    
    // MARK: – queue & state
    private struct SpeechItem {
        let text: String
        let autoHide: TimeInterval
        let typing: TimeInterval
        let lang: String
    }

    private static var speechQueue: [SpeechItem] = []
    private static var bubbleIsBusy = false

    private var speechQueue: [SpeechItem] {
        get { Self.speechQueue } set { Self.speechQueue = newValue }
    }
    private var bubbleIsBusy: Bool {
        get { Self.bubbleIsBusy } set { Self.bubbleIsBusy = newValue }
    }

    private static let ttsSynth = AVSpeechSynthesizer()   // one shared speaker

    // MARK: – dequeue & play / show next item
    private func dequeueAndShowNext() {
        // Nothing left → idle
        guard !speechQueue.isEmpty else {
            bubbleIsBusy = false
            helpIsLocked = false             // ➊ unlock
            updateHelpButton(enabled: true)  // ➊ re-enable
            restoreRobotIfNeeded()
            return
        }

        bubbleIsBusy = true
        let item = speechQueue.removeFirst()

        switch speechMode {

        // ───────── Voice only – no bubble ───────────────────────────────
        case .voiceOnly:
            Self.ttsSynth.delegate = self
            Self.ttsSynth.stopSpeaking(at: .immediate)

            let lang = item.lang
            let utt  = AVSpeechUtterance(string: item.text)

            // Use chosen voice if available, else fall back to English
            if let voice = AVSpeechSynthesisVoice(language: lang) {
                utt.voice = voice
            } else {
                utt.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
            utt.rate = AVSpeechUtteranceDefaultSpeechRate
            Self.ttsSynth.speak(utt)
            return


        // ───────── Bubble only – no sound ───────────────────────────────
        case .bubbleOnly:
            // Ensure the synth is silent
            Self.ttsSynth.stopSpeaking(at: .immediate)

            showBubble(text: item.text,
                       autoHide: item.autoHide,
                       typingSpeed: item.typing) { [weak self] in
                self?.dequeueAndShowNext()           // chain to next
            }
        }
    }

    // MARK: Bubble presentation / typing

    private func showBubble(text: String,
                            autoHide: TimeInterval,
                            typingSpeed: TimeInterval,
                            onCompleted: @escaping () -> Void) {

        let bubble = currentOrNewBubble(charInterval: typingSpeed)
        shrinkRobotIfNeeded()

        bubble.alpha = 0
        bubble.transform = CGAffineTransform(translationX: 0, y: -8)
        UIView.animate(withDuration: 0.25) {
            bubble.alpha = 1
            bubble.transform = .identity
        }

        bubble.type(text: text) { [weak bubble] in
            guard autoHide > 0 else { onCompleted(); return }

            DispatchQueue.main.asyncAfter(deadline: .now() + autoHide) {
                UIView.animate(withDuration: 0.25, animations: {
                    bubble?.alpha = 0
                }, completion: { _ in
                    bubble?.removeFromSuperview()
                    onCompleted()
                })
            }
        }
    }

    private func currentOrNewBubble(charInterval: TimeInterval) -> SpeechBubbleView {
        if let existing = subviews.first(where: { $0 is SpeechBubbleView }) as? SpeechBubbleView {
            return existing
        }

        let bubble = SpeechBubbleView(charInterval: charInterval)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubble)

        NSLayoutConstraint.activate([
            bubble.centerXAnchor.constraint(equalTo: centerXAnchor),
            bubble.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ])
        return bubble
    }

    // MARK: Robot shrink / restore

    private static var restState: RobotRestState?
    private var restState: RobotRestState? {
        get { Self.restState }
        set { Self.restState = newValue }
    }

    private func shrinkRobotIfNeeded() {
        guard restState == nil, let ent = robotEntity else { return }

        restState = RobotRestState(scale: ent.scale, position: ent.position)
        let targetScale = restState!.scale * 0.85
        let targetPosY  = restState!.position.y - 0.1

        var t: Float = 0
        var sub: Cancellable?
        sub = rkView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] ev in
            guard let self else { return }
            t += Float(ev.deltaTime) / 0.25
            let f = min(t, 1)

            ent.scale    = simd_mix(restState!.scale, targetScale, SIMD3(repeating: f))
            ent.position = simd_mix(restState!.position,
                                    SIMD3(ent.position.x, targetPosY, ent.position.z),
                                    SIMD3(repeating: f))

            if f >= 1 { sub?.cancel(); sub = nil }
        }
    }

    private func restoreRobotIfNeeded() {
        guard
            subviews.first(where: { $0 is SpeechBubbleView }) == nil,
            let saved = restState,
            let ent   = robotEntity
        else { return }

        var t: Float = 0
        var sub: Cancellable?
        sub = rkView.scene.subscribe(to: SceneEvents.Update.self) { [self] ev in
            t += Float(ev.deltaTime) / 0.25
            let f = min(t, 1)

            ent.scale    = simd_mix(ent.scale,    saved.scale,    SIMD3(repeating: f))
            ent.position = simd_mix(ent.position, saved.position, SIMD3(repeating: f))

            if f >= 1 { sub?.cancel(); sub = nil; restState = nil }
        }
    }
}

// MARK: – UI controls (mute / help)
private enum RobotSpeechMode { case voiceOnly, bubbleOnly }
private var speechMode: RobotSpeechMode = .voiceOnly    // default = sound ON

private extension RobotView {

    /// Creates the two side buttons and sets the correct initial icon
    func addSideButtons() {
        
        let mute = makeSideButton(systemName:"",
                                  action:#selector(toggleMute))
        muteButton = mute
        
        let help = makeSideButton(systemName:"questionmark.circle",
                                  action:#selector(helpTapped))
        helpButton = help
        
        
        addSubview(mute)
        addSubview(help)
        
        NSLayoutConstraint.activate([
            mute.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            mute.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            mute.widthAnchor.constraint(equalToConstant: 32),
            mute.heightAnchor.constraint(equalTo: mute.widthAnchor),
            
            help.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            help.topAnchor.constraint(equalTo: mute.bottomAnchor, constant: 12),
            help.widthAnchor.constraint(equalTo: mute.widthAnchor),
            help.heightAnchor.constraint(equalTo: mute.heightAnchor)
        ])
        
        updateMuteIcon()              // ← sets the right icon *now*
        updateHelpButton(enabled:true)
    }

    private func updateHelpButton(enabled: Bool) {
        helpButton?.isEnabled = enabled
        helpButton?.alpha     = enabled ? 1.0 : 0.4
    }

    
    func makeSideButton(systemName: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.tintColor = .systemOrange
        b.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        b.layer.cornerRadius = 16
        if !systemName.isEmpty {                // caller may set icon later
            b.setImage(UIImage(systemName: systemName), for: .normal)
        }
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    // MARK: – Button actions
    @objc func toggleMute(_ sender: UIButton) {
        speechMode = (speechMode == .voiceOnly) ? .bubbleOnly : .voiceOnly
        updateMuteIcon()
    }

    @objc private func helpTapped(_ sender: UIButton) {

        // already queued a help-script and it hasn't finished yet → ignore tap
        guard !helpIsLocked else { return }

        // ask the current VC for its help script
        guard let script = helpProvider?.robotHelpScript(),
              !script.isEmpty else { return }

        helpIsLocked = true                 // lock until the script finishes
        updateHelpButton(enabled: false)

        // ---------------------------------------------------------------
        //  NEW PART: push the help lines *after* whatever is already
        //  in the queue (or currently playing).  Order is preserved.
        // ---------------------------------------------------------------
        for line in script { speak(line) }
        // If the robot wasn’t busy, kick-off the queue right away.
        // If it *was* busy, `dequeueAndShowNext()` will be called automatically
        // when the current sentence (voice or bubble) finishes.
        if !bubbleIsBusy {
            dequeueAndShowNext()
        }
    }


    /// Sets the mute button’s icon so it always reflects the current mode
    private func updateMuteIcon() {
        let icon = (speechMode == .voiceOnly) ? "speaker.wave.2.fill"
                                              : "speaker.slash.fill"
        muteButton?.setImage(UIImage(systemName: icon), for: .normal)
    }
}


// MARK: – AVSpeechSynthesizerDelegate
// (Put this anywhere in the same extension / file)
extension RobotView: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        // Called when voice-only sentence ends → proceed with queue
        dequeueAndShowNext()
    }
}


extension RobotView {
    func safelyAttach(to view: UIView,
                      below titleLabel: UIView,
                      height: CGFloat,
                      heightConstraintStorage: inout NSLayoutConstraint?) {
        // Remove from previous superview
        self.removeFromSuperview()

        // Deactivate old constraint if needed
        heightConstraintStorage?.isActive = false

        // Add to new superview
        self.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)

        // Create new constraint
        let heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
        heightConstraint.priority = .required
        heightConstraint.isActive = true
        heightConstraintStorage = heightConstraint

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
}
