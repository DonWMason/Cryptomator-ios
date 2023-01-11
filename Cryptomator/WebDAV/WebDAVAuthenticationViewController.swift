//
//  WebDAVAuthenticationViewController.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 06.04.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import Combine
import CryptomatorCloudAccessCore
import CryptomatorCommonCore
import Promises
import SwiftUI
import UIKit

class WebDAVAuthenticationViewController: UIViewController {
	weak var coordinator: (Coordinator & WebDAVAuthenticating)?
	private let viewModel: WebDAVAuthenticationViewModel
	private var cancellables = Set<AnyCancellable>()
	private var hud: ProgressHUD?

	init(viewModel: WebDAVAuthenticationViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	@MainActor dynamic required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupSwiftUIView()

		title = "WebDAV"
		let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		navigationItem.leftBarButtonItem = cancelButton
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationItem.rightBarButtonItem = doneButton
		viewModel.$state.sink { [weak self] state in
			self?.handleState(state)
		}.store(in: &cancellables)
		viewModel.saveButtonIsEnabled.sink { saveButtonIsEnabled in
			doneButton.isEnabled = saveButtonIsEnabled
		}.store(in: &cancellables)
	}

	@objc func done() {
		viewModel.saveAccount()
	}

	func handleState(_ state: WebDAVAuthenticationViewModel.State) {
		switch state {
		case .authenticating:
			showHUD()
		case let .error(error):
			handleError(error)
		case let .authenticated(credential):
			hud?.transformToSelfDismissingSuccess().then {
				self.coordinator?.authenticated(with: credential)
			}
		case .initial, .insecureConnectionNotAllowed, .untrustedCertificate:
			break
		}
	}

	func handleError(_ error: Error) {
		let precondition: Promise<Void>
		if let hud = hud {
			precondition = hud.dismiss(animated: true)
		} else {
			precondition = Promise(())
		}
		precondition.then { [weak self] in
			guard let self = self else { return }
			self.coordinator?.handleError(error, for: self)
		}
	}

	func showHUD() {
		hud = ProgressHUD()

		hud?.text = LocalizedString.getValue("common.hud.authenticating")
		hud?.show(presentingViewController: self)
		hud?.showLoadingIndicator()
	}

	@objc func cancel() {
		coordinator?.cancel()
	}

	private func setupSwiftUIView() {
		let child = UIHostingController(rootView: WebDAVAuthentication(viewModel: viewModel))
		addChild(child)
		view.addSubview(child.view)
		child.didMove(toParent: self)
		child.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate(child.view.constraints(equalTo: view))
	}
}

#if DEBUG
import CryptomatorCloudAccessCore
import Promises
import SwiftUI

struct WebDAVAuthenticationVCPreview: PreviewProvider {
	static var previews: some View {
		WebDAVAuthenticationViewController(viewModel: .init()).toPreview()
	}
}
#endif
