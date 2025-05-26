//
//  SinglePlanCell.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit

class SinglePlanCell: UITableViewCell {
    
    let dayLabel = UILabel()
    let exercisesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        dayLabel.font = UIFont(name: "Avenir", size: 18)
        dayLabel.textColor = .white
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dayLabel)

        exercisesLabel.font = UIFont(name: "Avenir", size: 14)
        exercisesLabel.textColor = .white
        exercisesLabel.numberOfLines = 0
        exercisesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exercisesLabel)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            exercisesLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 8),
            exercisesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exercisesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            exercisesLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(day: PlanDayEntity) {
        // Set up the day label
        dayLabel.text = "Day \(day.dayIndex)"

        // Add exercises under each day (if any)
        var exercisesText = ""
        if let exercises = day.exercises as? Set<PlanExerciseEntity> {
            exercisesText = exercises.map { "\($0.name ?? "Exercise") – \($0.sets) × \($0.reps)" }.joined(separator: "\n")
        }
        exercisesLabel.text = exercisesText
    }
}
