import AppAuthCore
import CryptomatorCloudAccessCore
import SwiftUI
import UIKit

public protocol HubAuthenticationCoordinatorDelegate: AnyObject {
	@MainActor
	func userDidCancelHubAuthentication()

	@MainActor
	func userDismissedHubAuthenticationErrorMessage()
}

public final class HubAuthenticationCoordinator: Coordinator {
	public var childCoordinators = [Coordinator]()
	public var navigationController: UINavigationController
	public weak var parent: Coordinator?

	private let vaultConfig: UnverifiedVaultConfig
	private let hubAuthenticator: HubAuthenticating
	private var progressHUD: ProgressHUD?
	private let unlockHandler: HubVaultUnlockHandler
	private weak var delegate: HubAuthenticationCoordinatorDelegate?

	public init(navigationController: UINavigationController,
	            vaultConfig: UnverifiedVaultConfig,
	            hubAuthenticator: HubAuthenticating,
	            unlockHandler: HubVaultUnlockHandler,
	            parent: Coordinator?,
	            delegate: HubAuthenticationCoordinatorDelegate) {
		self.navigationController = navigationController
		self.vaultConfig = vaultConfig
		self.hubAuthenticator = hubAuthenticator
		self.unlockHandler = unlockHandler
		self.parent = parent
		self.delegate = delegate
	}

	public func start() {
		guard let hubConfig = vaultConfig.allegedHubConfig else {
			handleError(HubAuthenticationViewModelError.missingHubConfig, for: navigationController, onOKTapped: { [weak self] in
				guard let self else { return }
				parent?.childDidFinish(self)
			})
			return
		}
		Task { @MainActor in
			let authenticator = HubUserAuthenticator(hubAuthenticator: hubAuthenticator, viewController: navigationController)
			let authState: OIDAuthState
			do {
				authState = try await authenticator.authenticate(with: hubConfig)
			} catch let error as NSError where error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
				// do not show alert if user canceled it on purpose
				delegate?.userDidCancelHubAuthentication()
				parent?.childDidFinish(self)
				return
			} catch {
				handleError(error, for: navigationController, onOKTapped: { [weak self] in
					guard let self else { return }
					delegate?.userDismissedHubAuthenticationErrorMessage()
					parent?.childDidFinish(self)
				})
				return
			}
			let viewModel = HubAuthenticationViewModel(authState: authState,
			                                           vaultConfig: vaultConfig,
			                                           unlockHandler: unlockHandler,
			                                           delegate: self)
			await viewModel.continueToAccessCheck()
			guard !viewModel.isLoggedIn else {
				// Do not show the authentication view if the user already authenticated successfully
				return
			}
			navigationController.setNavigationBarHidden(false, animated: false)
			let viewController = HubAuthenticationViewController(viewModel: viewModel)
			navigationController.pushViewController(viewController, animated: true)
		}
	}

	private func showProgressHUD() {
		assert(progressHUD == nil, "showProgressHUD called although one is already shown")
		progressHUD = ProgressHUD()
		progressHUD?.show(presentingViewController: navigationController)
		progressHUD?.showLoadingIndicator()
	}

	private func hideProgressHUD() async {
		await withCheckedContinuation { continuation in
			progressHUD?.dismiss(animated: true, completion: { [weak self] in
				continuation.resume()
				self?.progressHUD = nil
			})
		}
	}
}

extension HubAuthenticationCoordinator: HubAuthenticationViewModelDelegate {
	public func hubAuthenticationViewModelWantsToShowLoadingIndicator() {
		showProgressHUD()
	}

	public func hubAuthenticationViewModelWantsToHideLoadingIndicator() async {
		await hideProgressHUD()
	}
}
