//
//  VaultDetailCoordinator.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 20.10.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CocoaLumberjackSwift
import CryptomatorCommonCore
import CryptomatorFileProvider
import GRDB
import Promises
import UIKit

class VaultDetailCoordinator: Coordinator {
	var childCoordinators = [Coordinator]()

	var navigationController: UINavigationController
	private let vaultInfo: VaultInfo

	init(vaultInfo: VaultInfo, navigationController: UINavigationController) {
		self.vaultInfo = vaultInfo
		self.navigationController = navigationController
	}

	func start() {
		let viewModel = VaultDetailViewModel(vaultInfo: vaultInfo)
		let vaultDetailViewController = VaultDetailViewController(viewModel: viewModel)
		vaultDetailViewController.coordinator = self
		navigationController.pushViewController(vaultDetailViewController, animated: true)
	}

	func unlockVault(_ vault: VaultInfo, biometryTypeName: String) -> Promise<Void> {
		let modalNavigationController = BaseNavigationController()
		let pendingAuthentication = Promise<Void>.pending()
		let child = VaultDetailUnlockCoordinator(navigationController: modalNavigationController, vault: vault, biometryTypeName: biometryTypeName, pendingAuthentication: pendingAuthentication)
		child.parentCoordinator = self
		childCoordinators.append(child)
		navigationController.topViewController?.present(modalNavigationController, animated: true)
		child.start()
		return pendingAuthentication
	}

	func renameVault() {
		let database: DatabaseWriter
		do {
			let domain = NSFileProviderDomain(vaultUID: vaultInfo.vaultUID, displayName: vaultInfo.vaultName)
			let fileproviderDatabaseURL = DatabaseHelper.getDatabaseURL(for: domain)
			database = try DatabaseHelper.getMigratedDB(at: fileproviderDatabaseURL)
		} catch {
			DDLogError("Get migrated fileprovider DB failed with error: \(error)")
			return
		}
		let viewModel = RenameVaultViewModel(vaultInfo: vaultInfo, maintenanceManager: MaintenanceDBManager(database: database))
		let renameVaultViewController = RenameVaultViewController(viewModel: viewModel)
		renameVaultViewController.title = vaultInfo.vaultName
		renameVaultViewController.coordinator = self
		navigationController.pushViewController(renameVaultViewController, animated: true)
	}
}

extension VaultDetailCoordinator: VaultNaming {
	func setVaultName(_ name: String) {
		guard let topViewController = navigationController.topViewController, topViewController is RenameVaultViewController else {
			return
		}
		navigationController.popViewController(animated: true)
	}
}
