//
//  TabBarViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/1/2024.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set default selected tab to "Work Out"
        selectedIndex = 1

        // Set localized titles
        localizeTabBarItems()

        // Customize appearance
        customizeTabBarAppearance()
        customizeTabBarFontAndLayout()
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let fromVC = selectedViewController,
              let toIndex = tabBar.items?.firstIndex(of: item),
              let toVC = viewControllers?[toIndex],
              fromVC != toVC else { return }

        animateTabTransition(from: fromVC.view, to: toVC.view)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTabBarColorsForCurrentInterfaceStyle()
        }
    }

    private func localizeTabBarItems() {
        guard let tabBarItems = tabBar.items else { return }

        let localizedTitles = [
            NSLocalizedString("tab_stats", comment: "Stats tab"),
            NSLocalizedString("tab_workout", comment: "Workout tab"),
            NSLocalizedString("tab_friends", comment: "Friends tab")
        ]

        for (index, item) in tabBarItems.enumerated() where index < localizedTitles.count {
            item.title = localizedTitles[index]
        }
    }

    private func customizeTabBarAppearance() {
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
        tabBar.barTintColor = UIColor.black.withAlphaComponent(0.5)

        updateTabBarColorsForCurrentInterfaceStyle()
    }

    private func updateTabBarColorsForCurrentInterfaceStyle() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        tabBar.tintColor = UIColor.systemOrange
        tabBar.unselectedItemTintColor = isDarkMode ? UIColor.white : UIColor.black
    }

    private func customizeTabBarFontAndLayout() {
        guard let tabBarItems = tabBar.items else { return }

        for (index, item) in tabBarItems.enumerated() {
            if index == 1 {
                // Middle tab - larger font and icon
                item.setTitleTextAttributes([
                    .font: UIFont(name: "Avenir", size: 15.0)!
                ], for: .normal)

                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
                item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                item.image = item.image?.withConfiguration(config)
            } else {
                item.setTitleTextAttributes([
                    .font: UIFont(name: "Avenir", size: 13.0)!
                ], for: .normal)

                item.titlePositionAdjustment = .zero
                item.imageInsets = .zero
            }
        }
    }
    
    private func animateTabTransition(from fromView: UIView, to toView: UIView) {
        let transitionOptions: UIView.AnimationOptions = [.transitionCrossDissolve, .curveEaseInOut]

        UIView.transition(from: fromView, to: toView, duration: 0.25, options: transitionOptions) { _ in
            // Ensure the layout is refreshed after transition
            toView.setNeedsLayout()
            toView.layoutIfNeeded()
        }
    }

}
