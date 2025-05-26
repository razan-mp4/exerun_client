//
//  StatsDiagramView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 2/5/2025.
//

import UIKit
import FSCalendar

final class StatsDiagramView: UIView {

    // MARK: - Subviews

    let dateRangeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Select Date Range", for: .normal)
        btn.setImage(UIImage(systemName: "calendar"), for: .normal)
        btn.tintColor = .label
        btn.setTitleColor(.label, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Avenir", size: 15)
        btn.semanticContentAttribute = .forceRightToLeft
        btn.contentHorizontalAlignment = .leading
        return btn
    }()

    let calendarBackgroundView: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }.withAlphaComponent(1.0)
        return v
    }()

    let diagramWrapper: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.backgroundColor = UIColor.systemGray6
        return v
    }()

    let diagramView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4
        return v
    }()

    private let calendarView: FSCalendar = {
        let cal = FSCalendar()
        cal.scope = .month
        cal.allowsMultipleSelection = true
        cal.translatesAutoresizingMaskIntoConstraints = false
        cal.appearance.selectionColor = .systemOrange
        cal.appearance.todayColor = .systemOrange.withAlphaComponent(0.3)
        cal.appearance.headerTitleColor = .systemOrange
        cal.appearance.weekdayTextColor = .systemOrange
        cal.appearance.titleDefaultColor = .label
        cal.appearance.titleWeekendColor = .systemOrange
        cal.backgroundColor = .clear
        return cal
    }()

    private let scrollView = UIScrollView()
    private let buttonContainer = UIStackView()

    private let activityDropdown = UIStackView()
    private var isDropdownVisible = false

    private var activityButton: UIButton!
    private var metricButtons: [UIButton] = []
    private var selectedMetricButton: UIButton?

    private var rangeStartDate: Date?
    private var rangeEndDate: Date?

    private let workoutTypes = ["All", "Running", "Cycling", "Hiking", "Skiing", "Quick", "Sets Running"]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        [dateRangeButton, diagramWrapper, scrollView, calendarBackgroundView, activityDropdown].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        calendarBackgroundView.addSubview(calendarView)
        calendarView.delegate = self
        calendarView.dataSource = self
        bringSubviewToFront(calendarBackgroundView)

        activityDropdown.axis = .vertical
        activityDropdown.alignment = .fill
        activityDropdown.distribution = .fillEqually
        activityDropdown.spacing = 4
        activityDropdown.isHidden = true
        activityDropdown.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }
        activityDropdown.layer.cornerRadius = 8
        activityDropdown.layer.borderColor = UIColor.systemGray4.cgColor
        activityDropdown.layer.borderWidth = 1

        workoutTypes.forEach { type in
            let btn = UIButton(type: .system)
            btn.setTitle(type, for: .normal)
            btn.setTitleColor(.label, for: .normal)
            btn.titleLabel?.font = UIFont(name: "Avenir", size: 14)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            btn.addTarget(self, action: #selector(selectWorkoutType(_:)), for: .touchUpInside)
            activityDropdown.addArrangedSubview(btn)
        }

        diagramWrapper.addSubview(diagramView)
        diagramView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.showsHorizontalScrollIndicator = false
        buttonContainer.axis = .horizontal
        buttonContainer.spacing = 12
        buttonContainer.distribution = .fill
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonContainer)

        activityButton = makeMetricButton(title: "Activity ⌄ (All)", isHighlighted: true)
        activityButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        buttonContainer.addArrangedSubview(activityButton)

        ["Frequency", "Distance", "Elevation", "Time"].forEach { title in
            let b = makeMetricButton(title: title)
            b.addTarget(self, action: #selector(metricTapped(_:)), for: .touchUpInside)
            metricButtons.append(b)
            buttonContainer.addArrangedSubview(b)
        }

        if let defaultBtn = metricButtons.first {
            selectMetricButton(defaultBtn)
        }

        dateRangeButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dateRangeButton.topAnchor.constraint(equalTo: topAnchor),
            dateRangeButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            dateRangeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            dateRangeButton.heightAnchor.constraint(equalToConstant: 30),

            calendarBackgroundView.topAnchor.constraint(equalTo: dateRangeButton.bottomAnchor),
            calendarBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarBackgroundView.heightAnchor.constraint(equalToConstant: 300),

            calendarView.topAnchor.constraint(equalTo: calendarBackgroundView.topAnchor, constant: -10),
            calendarView.bottomAnchor.constraint(equalTo: calendarBackgroundView.bottomAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarBackgroundView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarBackgroundView.trailingAnchor),

            activityDropdown.bottomAnchor.constraint(equalTo: scrollView.topAnchor, constant: -4),
            activityDropdown.leadingAnchor.constraint(equalTo: activityButton.leadingAnchor),
            activityDropdown.widthAnchor.constraint(equalToConstant: 140),

            diagramWrapper.topAnchor.constraint(equalTo: dateRangeButton.bottomAnchor, constant: 10),
            diagramWrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            diagramWrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            diagramWrapper.heightAnchor.constraint(equalToConstant: 200),

            diagramView.topAnchor.constraint(equalTo: diagramWrapper.topAnchor),
            diagramView.bottomAnchor.constraint(equalTo: diagramWrapper.bottomAnchor),
            diagramView.leadingAnchor.constraint(equalTo: diagramWrapper.leadingAnchor),
            diagramView.trailingAnchor.constraint(equalTo: diagramWrapper.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: diagramWrapper.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 36),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            buttonContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            buttonContainer.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    private func makeMetricButton(title: String, isHighlighted: Bool = false) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(isHighlighted ? .systemOrange : .label, for: .normal)
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 6
        b.layer.borderColor = isHighlighted ? UIColor.systemOrange.cgColor : UIColor.label.cgColor
        b.titleLabel?.font = UIFont(name: "Avenir", size: 14)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return b
    }

    private func selectMetricButton(_ button: UIButton) {
        selectedMetricButton?.backgroundColor = .clear
        selectedMetricButton?.setTitleColor(.label, for: .normal)

        button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        button.setTitleColor(.systemOrange, for: .normal)
        selectedMetricButton = button
    }

    // MARK: - Actions

    @objc private func toggleCalendar() {
        calendarBackgroundView.isHidden.toggle()
        if !calendarBackgroundView.isHidden {
            calendarView.selectedDates.forEach { calendarView.deselect($0) }
            rangeStartDate = nil
            rangeEndDate = nil
        }
    }

    @objc private func toggleDropdown() {
        isDropdownVisible.toggle()
        activityDropdown.isHidden = !isDropdownVisible
    }

    @objc private func selectWorkoutType(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        activityButton.setTitle("Activity ⌄ (\(title))", for: .normal)
        toggleDropdown()
    }

    @objc private func metricTapped(_ sender: UIButton) {
        guard sender != selectedMetricButton else { return }
        selectMetricButton(sender)
    }
}

extension StatsDiagramView: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if rangeStartDate == nil {
            rangeStartDate = date
        } else if rangeEndDate == nil {
            if date < rangeStartDate! {
                rangeEndDate = rangeStartDate
                rangeStartDate = date
            } else {
                rangeEndDate = date
            }

            var current = rangeStartDate!
            while current <= rangeEndDate! {
                calendar.select(current)
                current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
            }

            let fmt = DateFormatter()
            fmt.dateFormat = "dd/MM/yy"
            let text = "\(fmt.string(from: rangeStartDate!)) — \(fmt.string(from: rangeEndDate!))"
            dateRangeButton.setTitle(text, for: .normal)
            calendarBackgroundView.isHidden = true
        } else {
            calendar.selectedDates.forEach { calendar.deselect($0) }
            rangeStartDate = date
            rangeEndDate = nil
        }
    }
}
