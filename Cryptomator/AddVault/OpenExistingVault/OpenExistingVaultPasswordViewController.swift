//
//  OpenExistingVaultPasswordViewController.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 27.01.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCommonCore
import CryptomatorCryptoLib
import UIKit

class OpenExistingVaultPasswordViewController: SingleSectionTableViewController {
	weak var coordinator: (Coordinator & VaultInstalling)?
	lazy var verifyButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: LocalizedString.getValue("common.button.verify"), style: .done, target: self, action: #selector(verify))
		button.isEnabled = false
		return button
	}()

	private var viewModel: OpenExistingVaultPasswordViewModelProtocol

	private var viewToShake: UIView? {
		return navigationController?.view.superview // shake the whole modal dialog
	}

	init(viewModel: OpenExistingVaultPasswordViewModelProtocol) {
		self.viewModel = viewModel
		super.init()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = LocalizedString.getValue("addVault.openExistingVault.title")
		navigationItem.rightBarButtonItem = verifyButton
		tableView.register(PasswordFieldCell.self, forCellReuseIdentifier: "PasswordFieldCell")
		tableView.rowHeight = 44
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		viewToShake?.cancelShaking()
	}

	@objc func verify() {
		let hud = ProgressHUD()
		hud.text = LocalizedString.getValue("addVault.openExistingVault.progress")
		hud.show(presentingViewController: self)
		hud.showLoadingIndicator()
		viewModel.addVault().then {
			hud.transformToSelfDismissingSuccess()
		}.then { [weak self] in
			guard let self = self else { return }
			self.coordinator?.showSuccessfullyAddedVault(withName: self.viewModel.vaultName, vaultUID: self.viewModel.vaultUID)
		}.catch { [weak self] error in
			self?.handleError(error, hud: hud)
		}
	}

	@objc func textFieldDidChange(_ textField: UITextField) {
		viewModel.password = textField.text
		if textField.text?.isEmpty ?? true {
			verifyButton.isEnabled = false
		} else {
			verifyButton.isEnabled = true
		}
	}

	// MARK: - UITableViewDataSource

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// swiftlint:disable:next force_cast
		let cell = tableView.dequeueReusableCell(withIdentifier: "PasswordFieldCell", for: indexPath) as! PasswordFieldCell
		cell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		cell.textField.becomeFirstResponder()
		return cell
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return viewModel.footerTitle
	}

	// MARK: - Internal

	private func handleError(_ error: Error, hud: ProgressHUD) {
		if case MasterkeyFileError.invalidPassphrase = error {
			viewToShake?.shake()
		} else {
			coordinator?.handleError(error, for: self)
		}
	}
}

#if DEBUG
import Promises
import SwiftUI

private class OpenExistingVaultMasterkeyProcessingViewModelMock: OpenExistingVaultPasswordViewModelProtocol {
	let vaultUID = ""

	var password: String?
	var footerTitle: String {
		"Enter password for \"\(vaultName)\""
	}

	let vaultName = "Work"

	func addVault() -> Promise<Void> {
		Promise(())
	}
}

struct OpenExistingVaultMasterkeyProcessingVC_Preview: PreviewProvider {
	static var previews: some View {
		OpenExistingVaultPasswordViewController(viewModel: OpenExistingVaultMasterkeyProcessingViewModelMock()).toPreview()
	}
}
#endif
