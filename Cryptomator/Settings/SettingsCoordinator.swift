//
//  SettingsCoordinator.swift
//  Cryptomator
//
//  Created by Tobias Hagemann on 04.06.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CocoaLumberjackSwift
import CryptomatorCommonCore
import Foundation
import UIKit

class SettingsCoordinator: Coordinator {
	var childCoordinators = [Coordinator]()
	var navigationController: UINavigationController
	weak var parentCoordinator: MainCoordinator?

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func start() {
		let settingsViewController = SettingsViewController(viewModel: SettingsViewModel())
		settingsViewController.coordinator = self
		navigationController.pushViewController(settingsViewController, animated: false)
	}

	func showAbout() {
		let child = AboutCoordinator(navigationController: navigationController)
		childCoordinators.append(child) // TODO: remove missing?
		child.start()
	}

	func sendLogFile(sourceView: UIView) throws {
		let logsDirectoryURL = URL(fileURLWithPath: DDFileLogger.sharedInstance.logFileManager.logsDirectory)
		let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager.default.createDirectory(at: tmpDirURL, withIntermediateDirectories: true)
		let zippedLogsURL = tmpDirURL.appendingPathComponent("Logs.zip", isDirectory: false)
		try logsDirectoryURL.zipFolder(toFileAt: zippedLogsURL)
		let activityController = UIActivityViewController(activityItems: [zippedLogsURL], applicationActivities: nil)
		activityController.completionWithItemsHandler = { _, _, _, _ -> Void in
			try? FileManager.default.removeItem(at: tmpDirURL)
		}
		activityController.popoverPresentationController?.sourceView = sourceView
		activityController.popoverPresentationController?.sourceRect = sourceView.bounds
		navigationController.present(activityController, animated: true)
	}

	func showCloudServices() {
		let viewModel = ChooseCloudViewModel(clouds: [.dropbox, .googleDrive, .oneDrive, .webDAV], headerTitle: "")
		let chooseCloudVC = ChooseCloudViewController(viewModel: viewModel)
		chooseCloudVC.title = LocalizedString.getValue("settings.cloudServices")
		chooseCloudVC.coordinator = self
		chooseCloudVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
		navigationController.pushViewController(chooseCloudVC, animated: true)
	}

	func openContact() {
		if let contactURL = URL(string: "https://cryptomator.org/contact/") {
			UIApplication.shared.open(contactURL)
		}
	}

	func openRateApp() {
		if let rateAppURL = URL(string: "https://apps.apple.com/app/cryptomator/id953086535?action=write-review") {
			UIApplication.shared.open(rateAppURL)
		}
	}

	func showUnlockFullVersion() {
		let child = SettingsPurchaseCoordinator(navigationController: navigationController)
		childCoordinators.append(child) // TODO: remove missing?
		child.start()
	}

	@objc func close() {
		navigationController.dismiss(animated: true)
		parentCoordinator?.childDidFinish(self)
	}
}

extension SettingsCoordinator: CloudChoosing {
	func showAccountList(for cloudProviderType: CloudProviderType) {
		let viewModel = AccountListViewModel(with: cloudProviderType)
		let accountListVC = AccountListViewController(with: viewModel)
		accountListVC.coordinator = self
		navigationController.pushViewController(accountListVC, animated: true)
	}
}

extension SettingsCoordinator: AccountListing {
	func showAddAccount(for cloudProviderType: CloudProviderType, from viewController: UIViewController) {
		let authenticator = CloudAuthenticator(accountManager: CloudProviderAccountDBManager.shared)
		_ = authenticator.authenticate(cloudProviderType, from: viewController)
	}

	func selectedAccont(_ account: AccountInfo) throws {}

	func showEdit(for account: AccountInfo) {}
}

private class SettingsPurchaseCoordinator: PurchaseCoordinator, PoppingCloseCoordinator {
	let oldTopViewController: UIViewController?

	override init(navigationController: UINavigationController) {
		self.oldTopViewController = navigationController.topViewController
		super.init(navigationController: navigationController)
	}

	override func start() {
		let purchaseViewController = PurchaseViewController(viewModel: SettingsPurchaseViewModel())
		purchaseViewController.coordinator = self
		purchaseViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationController.pushViewController(purchaseViewController, animated: true)
	}

	override func getUpgradeCoordinator() -> UpgradeCoordinator {
		return SettingsUpgradeCoordinator(navigationController: navigationController, oldTopViewController: oldTopViewController)
	}

	override func close() {
		popToOldTopViewController()
	}

	@objc private func done() {
		super.close()
	}
}

private class SettingsUpgradeCoordinator: UpgradeCoordinator, PoppingCloseCoordinator {
	let oldTopViewController: UIViewController?

	init(navigationController: UINavigationController, oldTopViewController: UIViewController?) {
		self.oldTopViewController = oldTopViewController
		super.init(navigationController: navigationController)
	}

	override func close() {
		popToOldTopViewController()
	}

	override func start() {
		let upgradeViewController = UpgradeViewController(viewModel: SettingsUpgradeViewModel())
		upgradeViewController.coordinator = self
		upgradeViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationController.pushViewController(upgradeViewController, animated: true)
	}

	@objc private func done() {
		super.close()
	}
}
