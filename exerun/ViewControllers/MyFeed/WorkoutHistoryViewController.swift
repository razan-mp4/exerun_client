//
//  WorkoutHistoryViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 2/5/2025.
//

import UIKit
import CoreData

final class WorkoutHistoryViewController: UIViewController {

    // ───────────────────────────── UI
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("back_button", comment: ""), for: .normal)
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return b
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .secondarySystemBackground
        iv.layer.cornerRadius = 40
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Avenir-Medium", size: 22)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .systemOrange
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var collectionView: UICollectionView = {
        let spacing: CGFloat = 1              // hair-line gaps
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing      = spacing

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(WorkoutImageCell.self, forCellWithReuseIdentifier: WorkoutImageCell.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // ───────────────────────────── Data
    private var previews: [Preview] = []

    private struct Preview {
        let objectID: NSManagedObjectID
        let image   : UIImage?
    }

    private var container: NSPersistentContainer {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    // ───────────────────────────── Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        loadUser()
        fetchPreviews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(workoutDidSave(_:)),
            name: .workoutDidSave,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // ───────────────────────────── Setup
    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(separator)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            profileImageView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            separator.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            collectionView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // ───────────────────────────── Header content
    private func loadUser() {
        guard let user = UserStorage.shared.getUser() else { return }
        nameLabel.text = "\(user.name) \(user.surname)"

        if
            let profile = ProfileStorage.shared.getProfile(),
            let data = profile.imageData,
            let img = UIImage(data: data)
        {
            profileImageView.image = img
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle")
            profileImageView.tintColor = .systemGray
        }
    }

    // ───────────────────────────── Fetch workouts
    private func fetchPreviews() {
        let ctx = container.viewContext
        // Replace "BaseWorkOutEntity" with your root class name if different
        let req = NSFetchRequest<NSManagedObject>(entityName: "BaseWorkOutEntity")
        req.predicate = NSPredicate(format: "TRUEPREDICATE")  // includes sub-entities
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let list = try ctx.fetch(req)
            previews = list.compactMap { obj in
                guard let hasPic = obj as? HasImageData else { return nil }
                let img = hasPic.imageData.flatMap { UIImage(data: $0) }
                return Preview(objectID: obj.objectID, image: img)
            }
            collectionView.reloadData()
        } catch {
            print("❌ Fetch error:", error)
        }
    }

    // ───────────────────────────── Actions
    @objc private func handleBack() {
        dismiss(animated: true)
    }

    @objc private func workoutDidSave(_ note: Notification) {
        fetchPreviews()
    }
}

// ──────────────────────────────────────────────────────────────
// MARK: –  CollectionView
// ──────────────────────────────────────────────────────────────
extension WorkoutHistoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // Data count
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previews.count
    }

    // Cell config
    func collectionView(
        _ cv: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: WorkoutImageCell.reuseID,
                                          for: indexPath) as! WorkoutImageCell
        let preview = previews[indexPath.item]
        cell.configure(with: preview.image)
        return cell
    }

    // 3-in-a-row square sizing
    func collectionView(
        _ cv: UICollectionView,
        layout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spacing: CGFloat = 1
        let totalSpacing = spacing * 2
        let side = (cv.bounds.width - totalSpacing) / 3
        return CGSize(width: side, height: side)
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feed = WorkoutFeedViewController(
            objectIDs: previews.map(\.objectID),
            startAt:  indexPath.item
        )
        feed.modalPresentationStyle = .fullScreen
        present(feed, animated: true)
    }

}
