//
//  FileProviderItemUpdateDelegateMock.swift
//  CryptomatorFileProviderTests
//
//  Created by Philipp Schmid on 19.01.22.
//  Copyright © 2022 Skymatic GmbH. All rights reserved.
//

import FileProvider
import Foundation
@testable import CryptomatorFileProvider

final class FileProviderItemUpdateDelegateMock: FileProviderItemUpdateDelegate {
	// MARK: - signalWorkingSetUpdate

	var signalWorkingSetUpdateForCallsCount = 0
	var signalWorkingSetUpdateForCalled: Bool {
		signalWorkingSetUpdateForCallsCount > 0
	}

	var signalWorkingSetUpdateForReceivedItem: NSFileProviderItem?
	var signalWorkingSetUpdateForReceivedInvocations: [NSFileProviderItem] = []
	var signalWorkingSetUpdateForClosure: ((NSFileProviderItem) -> Void)?

	func signalWorkingSetUpdate(for item: NSFileProviderItem) {
		signalWorkingSetUpdateForCallsCount += 1
		signalWorkingSetUpdateForReceivedItem = item
		signalWorkingSetUpdateForReceivedInvocations.append(item)
		signalWorkingSetUpdateForClosure?(item)
	}

	// MARK: - signalUpdate

	var signalUpdateForCallsCount = 0
	var signalUpdateForCalled: Bool {
		signalUpdateForCallsCount > 0
	}

	var signalUpdateForReceivedItem: NSFileProviderItem?
	var signalUpdateForReceivedInvocations: [NSFileProviderItem] = []
	var signalUpdateForClosure: ((NSFileProviderItem) -> Void)?

	func signalUpdate(for item: NSFileProviderItem) {
		signalUpdateForCallsCount += 1
		signalUpdateForReceivedItem = item
		signalUpdateForReceivedInvocations.append(item)
		signalUpdateForClosure?(item)
	}

	// MARK: - removeItemFromWorkingSet

	var removeItemFromWorkingSetWithCallsCount = 0
	var removeItemFromWorkingSetWithCalled: Bool {
		removeItemFromWorkingSetWithCallsCount > 0
	}

	var removeItemFromWorkingSetWithReceivedIdentifier: NSFileProviderItemIdentifier?
	var removeItemFromWorkingSetWithReceivedInvocations: [NSFileProviderItemIdentifier] = []
	var removeItemFromWorkingSetWithClosure: ((NSFileProviderItemIdentifier) -> Void)?

	func removeItemFromWorkingSet(with identifier: NSFileProviderItemIdentifier) {
		removeItemFromWorkingSetWithCallsCount += 1
		removeItemFromWorkingSetWithReceivedIdentifier = identifier
		removeItemFromWorkingSetWithReceivedInvocations.append(identifier)
		removeItemFromWorkingSetWithClosure?(identifier)
	}

	// MARK: - removeItemsFromWorkingSet

	var removeItemsFromWorkingSetWithCallsCount = 0
	var removeItemsFromWorkingSetWithCalled: Bool {
		removeItemsFromWorkingSetWithCallsCount > 0
	}

	var removeItemsFromWorkingSetWithReceivedIdentifiers: [NSFileProviderItemIdentifier]?
	var removeItemsFromWorkingSetWithReceivedInvocations: [[NSFileProviderItemIdentifier]] = []
	var removeItemsFromWorkingSetWithClosure: (([NSFileProviderItemIdentifier]) -> Void)?

	func removeItemsFromWorkingSet(with identifiers: [NSFileProviderItemIdentifier]) {
		removeItemsFromWorkingSetWithCallsCount += 1
		removeItemsFromWorkingSetWithReceivedIdentifiers = identifiers
		removeItemsFromWorkingSetWithReceivedInvocations.append(identifiers)
		removeItemsFromWorkingSetWithClosure?(identifiers)
	}

	// MARK: - refreshWorkingSet

	var refreshWorkingSetCallsCount = 0
	var refreshWorkingSetCalled: Bool {
		refreshWorkingSetCallsCount > 0
	}

	var refreshWorkingSetClosure: (() -> Void)?

	func refreshWorkingSet() {
		refreshWorkingSetCallsCount += 1
		refreshWorkingSetClosure?()
	}

	// MARK: - updateWorkingSetItem

	var updateWorkingSetItemCallsCount = 0
	var updateWorkingSetItemCalled: Bool {
		updateWorkingSetItemCallsCount > 0
	}

	var updateWorkingSetItemReceivedItem: NSFileProviderItem?
	var updateWorkingSetItemReceivedInvocations: [NSFileProviderItem] = []
	var updateWorkingSetItemClosure: ((NSFileProviderItem) -> Void)?

	func updateWorkingSetItem(_ item: NSFileProviderItem) {
		updateWorkingSetItemCallsCount += 1
		updateWorkingSetItemReceivedItem = item
		updateWorkingSetItemReceivedInvocations.append(item)
		updateWorkingSetItemClosure?(item)
	}
}
