//
//  SpeechBubbleView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/4/2025.
//

import UIKit

class SpeechBubbleView: UIView {

    private let label: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "AvenirNext-Regular", size: 17)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var typingTimer: Timer?
    private var fullText = ""
    private var charIndex = 0
    private let charInterval: TimeInterval

    /// duration between characters (default 30 ms)
    init(charInterval: TimeInterval = 0.03) {
        self.charInterval = charInterval
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.78)
        layer.cornerRadius = 12
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            widthAnchor.constraint(lessThanOrEqualToConstant: 260)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func type(text: String, completion: @escaping () -> Void) {
        typingTimer?.invalidate()
        fullText = text
        charIndex = 0
        label.text = ""
        typingTimer = Timer.scheduledTimer(withTimeInterval: charInterval,
                                           repeats: true) { [weak self] t in
            guard let self else { return }
            self.charIndex += 1
            self.label.text = String(self.fullText.prefix(self.charIndex))

            if self.charIndex >= self.fullText.count {
                t.invalidate()
                completion()
            }
        }
    }

}
