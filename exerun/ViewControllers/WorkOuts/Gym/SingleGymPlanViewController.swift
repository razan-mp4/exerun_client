//
//  SingleGymPlanViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit
import CoreData

class SingleGymPlanViewController: UIViewController {
    
    var planEntity: GymPlanEntity!  // This will be injected from the previous VC
    private let tableView = UITableView()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Workout Plan"
        lbl.font = UIFont(name: "Avenir", size: 26)
        lbl.textColor = .systemOrange
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Back", for: .normal)
        btn.setTitleColor(.systemOrange, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupTableView()
    }
    
    private func setupUI() {
        // Background Image
        let backgroundImageView = UIImageView(image: UIImage(named: "rope_jumping"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // Add overlay to improve text visibility
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        
        // Title Label
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            // Background image constraints
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Overlay constraints
            overlay.topAnchor.constraint(equalTo: backgroundImageView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor),
            
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Back button constraints
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
        ])
    }
    
    private func setupTableView() {
        // Configure table view for displaying days and exercises
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SinglePlanCell.self, forCellReuseIdentifier: "PlanCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func getPlanDays() -> [PlanDayEntity] {
        // Extract and sort days from GymPlanEntity
        guard let days = planEntity.days as? Set<PlanDayEntity> else { return [] }
        return days.sorted { $0.dayIndex < $1.dayIndex }
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SingleGymPlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getPlanDays().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let day = getPlanDays()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath) as! SinglePlanCell
        
        // Configure the custom cell with the day's data
        cell.configure(day: day)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SingleGymPlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let day = getPlanDays()[indexPath.row]
        
        // Optional: Perform any logic when tapping on a day (if needed).
        print("Day \(day.dayIndex) selected")
    }
    
    // MARK: - Footer for adding space between cells
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.frame.size.height = 10 // Set the space between rows here
        footer.backgroundColor = .clear
        return footer
    }
    
}
