//
//  AllGymPlansViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit
import CoreData

final class AllGymPlansViewController: UIViewController {

    private let tableView = UITableView()
    private var plans: [GymPlanEntity] = []

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "All Your Saved Plans"
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
        fetchPlans()
        tableView.register(GymPlanCell.self, forCellReuseIdentifier: "GymPlanCell")

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPlans()
    }

    private func setupUI() {
        // Background
        let bg = UIImageView(image: UIImage(named: "rope_jumping"))
        bg.contentMode = .scaleAspectFill
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bg)

        // Add overlay to improve text visibility
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        // Add UI elements
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlanCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        view.addSubview(titleLabel)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            // Background constraints
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlay.topAnchor.constraint(equalTo: bg.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bg.bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func fetchPlans() {
        plans = GymPlanStorage.shared.fetchAllPlans()
        tableView.reloadData()
    }

    private func deletePlan(at indexPath: IndexPath) {
        let plan = plans[indexPath.row]
        GymPlanStorage.shared.deletePlan(plan)
        plans.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AllGymPlansViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let plan = plans[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "GymPlanCell", for: indexPath) as! GymPlanCell
        cell.configure(with: plan)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70  // Adjust based on your spacing needs
    }
}

// MARK: - UITableViewDelegate
extension AllGymPlansViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plan = plans[indexPath.row]
        // Here, the segue should be performed properly
        performSegue(withIdentifier: "ShowSingleGymPlan", sender: plan)
    }

    // Delete plan method
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            self.deletePlan(at: indexPath)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    // MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSingleGymPlan" {
            if let destinationVC = segue.destination as? SingleGymPlanViewController, let plan = sender as? GymPlanEntity {
                destinationVC.planEntity = plan
            }
        }
    }
}

