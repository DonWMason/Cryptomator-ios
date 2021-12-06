//
//  AddVaultCoordinator.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 12.01.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCommonCore
import Foundation
import UIKit

class AddVaultCoordinator: Coordinator {
	var childCoordinators = [Coordinator]()
	var navigationController: UINavigationController
	weak var parentCoordinator: MainCoordinator?

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func start() {
		let addVaultViewController = AddVaultViewController()
		addVaultViewController.coordinator = self
		navigationController.pushViewController(addVaultViewController, animated: false)
	}

	func createNewVault() {
		if isAllowedToCreateNewVault() {
			startCreateNewVaultFlow()
		} else {
			showUnlockFullVersion()
		}
	}

	func openExistingVault() {
		let child = OpenExistingVaultCoordinator(navigationController: navigationController)
		child.parentCoordinator = self
		childCoordinators.append(child)
		child.start()
	}

	func close() {
		navigationController.dismiss(animated: true)
		parentCoordinator?.childDidFinish(self)
	}

	func unlockedFullVersionFromCreateNewVault(navigationStack: [UIViewController]) {
		startCreateNewVaultFlow(navigationStack: navigationStack)
	}

	private func startCreateNewVaultFlow() {
		let setVaultNameVC = createSetVaultNameViewController()
		navigationController.pushViewController(setVaultNameVC, animated: true)
	}

	private func startCreateNewVaultFlow(navigationStack: [UIViewController]) {
		let setVaultNameVC = createSetVaultNameViewController()
		var updatedNavigationStack = navigationStack
		updatedNavigationStack.append(setVaultNameVC)
		navigationController.setViewControllers(updatedNavigationStack, animated: true)
	}

	private func createSetVaultNameViewController() -> SetVaultNameViewController {
		let viewModel = SetVaultNameViewModel()
		let setVaultNameVC = SetVaultNameViewController(viewModel: viewModel)
		setVaultNameVC.coordinator = self
		return setVaultNameVC
	}

	private func showUnlockFullVersion() {
		let child = AddVaultPurchaseCoordinator(navigationController: navigationController)
		childCoordinators.append(child)
		child.parentCoordinator = self
		child.start()
	}

	private func isAllowedToCreateNewVault() -> Bool {
		return UserDefaultsFullVersionChecker.shared.isFullVersion
	}
}

extension AddVaultCoordinator: VaultNaming {
	func setVaultName(_ name: String) {
		let createNewVaultCoordinator = CreateNewVaultCoordinator(navigationController: navigationController, vaultName: name)
		createNewVaultCoordinator.parentCoordinator = self
		childCoordinators.append(createNewVaultCoordinator)
		createNewVaultCoordinator.start()
	}
}

private class AddVaultPurchaseCoordinator: PurchaseCoordinator, PoppingCloseCoordinator {
	let oldTopViewController: UIViewController?
	weak var parentCoordinator: AddVaultCoordinator?
	private let oldNavigationControllerStack: [UIViewController]

	override init(navigationController: UINavigationController) {
		self.oldTopViewController = navigationController.topViewController
		self.oldNavigationControllerStack = navigationController.viewControllers
		super.init(navigationController: navigationController)
	}

	override func start() {
		let purchaseViewController = PurchaseViewController(viewModel: CreateNewVaultPurchaseViewModel())
		purchaseViewController.coordinator = self
		navigationController.pushViewController(purchaseViewController, animated: true)
	}

	override func unlockedPro() {
		parentCoordinator?.unlockedFullVersionFromCreateNewVault(navigationStack: oldNavigationControllerStack)
		parentCoordinator?.childDidFinish(self)
	}

	override func close() {
		popToOldTopViewController()
	}

	override func getUpgradeCoordinator() -> UpgradeCoordinator {
		return AddVaultUpgradeCoordinator(navigationController: navigationController, oldTopViewController: oldTopViewController)
	}
}

private class AddVaultUpgradeCoordinator: UpgradeCoordinator, PoppingCloseCoordinator {
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
		navigationController.pushViewController(upgradeViewController, animated: true)
	}
}

private class CreateNewVaultPurchaseViewModel: SettingsPurchaseViewModel {
	override var headerTitle: String {
		return LocalizedString.getValue("addVault.createNewVault.purchase")
	}
}
