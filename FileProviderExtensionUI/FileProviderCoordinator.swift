//
//  FileProviderCoordinator.swift
//  FileProviderExtensionUI
//
//  Created by Philipp Schmid on 29.06.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCommonCore
import FileProviderUI
import UIKit

class FileProviderCoordinator {
	private let extensionContext: FPUIActionExtensionContext
	private weak var hostViewController: UIViewController?
	private lazy var navigationController: UINavigationController = {
		let navigationController = UINavigationController()
		navigationController.navigationBar.barTintColor = UIColor(named: "primary")
		navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
		navigationController.navigationBar.tintColor = .white
		addViewControllerAsChildToHost(navigationController)
		return navigationController
	}()

	init(extensionContext: FPUIActionExtensionContext, hostViewController: UIViewController) {
		self.extensionContext = extensionContext
		self.hostViewController = hostViewController
	}

	func userCancelled() {
		extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
	}

	func startWith(error: Error) {
		let error = error as NSError
		let userInfo = error.userInfo
		guard let internalError = userInfo["internalError"] as? Error, let vaultName = userInfo["vaultName"] as? String, let pathRelativeToDocumentStorage = userInfo["pathRelativeToDocumentStorage"] as? String, let domainIdentifier = userInfo["domainIdentifier"] as? NSFileProviderDomainIdentifier else {
			showOnboarding()
			return
		}
		switch internalError {
		case let internalError as NSError where internalError == VaultPasswordManagerError.passwordNotFound as NSError:
			let domain = NSFileProviderDomain(identifier: domainIdentifier, displayName: vaultName, pathRelativeToDocumentStorage: pathRelativeToDocumentStorage)
			showPasswordScreen(for: domain)
		default:
			showOnboarding()
		}
	}

	func handleError(_ error: Error, for viewController: UIViewController) {
		let alertController = UIAlertController(title: LocalizedString.getValue("common.alert.error.title"), message: error.localizedDescription, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: LocalizedString.getValue("common.button.ok"), style: .default))
		viewController.present(alertController, animated: true)
	}

	func done() {
		extensionContext.completeRequest()
	}

	// MARK: - Onboarding

	func showOnboarding() {
		let onboardingVC = OnboardingViewController()
		onboardingVC.coordinator = self
		navigationController.pushViewController(onboardingVC, animated: false)
	}

	func openCryptomatorApp() {
		let url = URL(string: "cryptomator:")!
		extensionContext.open(url) { success in
			if success {
				self.userCancelled()
			}
		}
	}

	// MARK: - Vault Unlock

	func showPasswordScreen(for domain: NSFileProviderDomain) {
		let viewModel = UnlockVaultViewModel(domain: domain)
		let unlockVaultVC = UnlockVaultViewController(viewModel: viewModel)
		unlockVaultVC.coordinator = self
		navigationController.pushViewController(unlockVaultVC, animated: false)
	}

	// MARK: - Internal

	private func addViewControllerAsChildToHost(_ viewController: UIViewController) {
		guard let hostViewController = hostViewController else {
			return
		}
		hostViewController.addChild(viewController)
		hostViewController.view.addSubview(viewController.view)
		viewController.didMove(toParent: hostViewController)
	}
}
