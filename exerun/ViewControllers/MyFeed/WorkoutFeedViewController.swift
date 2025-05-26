//
//  WorkoutFeedViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/5/2025.
//

import UIKit
import CoreData

/// Vertical feed (à-la Instagram) listing all workouts.
final class WorkoutFeedViewController: UIViewController {

    // MARK: – Data
    private let objectIDs: [NSManagedObjectID]

    init(objectIDs: [NSManagedObjectID], startAt index: Int) {
        self.objectIDs = objectIDs
        super.init(nibName: nil, bundle: nil)
        self.startIndex = index
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: – Views
    private let table = UITableView(frame: .zero, style: .plain)
    private let topBar = UIView()
    private lazy var backBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("back_button", comment: ""), for: .normal)
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(close), for: .touchUpInside)
        return b
    }()
    private let titleLbl = UILabel()
    private var startIndex: Int = 0

    // MARK: –
    override func viewDidLoad() {
        super.viewDidLoad()

        // ---------- top bar ----------
        topBar.translatesAutoresizingMaskIntoConstraints = false
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        let bg = UIColor { t in
            t.userInterfaceStyle == .dark ? .black : .white
        }
        topBar.backgroundColor = bg
        backBtn.setTitle("Back", for: .normal)
        backBtn.setTitleColor(.systemOrange, for: .normal)
        backBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        titleLbl.text = "Workouts"
        titleLbl.font = UIFont(name: "Avenir-Medium", size: 18)
        topBar.addSubview(backBtn)
        topBar.addSubview(titleLbl)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            backBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            titleLbl.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        // ---------- table ----------
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        table.separatorStyle = .none
        table.rowHeight      = UITableView.automaticDimension
        table.estimatedRowHeight = 600
        table.dataSource = self
        table.register(WorkoutPostCell.self, forCellReuseIdentifier: "post")

        // scroll to initially tapped item
        DispatchQueue.main.async {
            let idx = IndexPath(row: self.startIndex, section: 0)
            self.table.scrollToRow(at: idx, at: .top, animated: false)
        }
    }

    @objc private func close() { dismiss(animated: true) }
}

// MARK: – DataSource
extension WorkoutFeedViewController: UITableViewDataSource {
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int {
        objectIDs.count
    }
    func tableView(_ tv: UITableView,
                   cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "post",
                                          for: ip) as! WorkoutPostCell
        cell.configure(with: objectIDs[ip.row]) {
            // callback so the cell can ask the table to update its height
            self.table.beginUpdates(); self.table.endUpdates()
        }
        return cell
    }
}
