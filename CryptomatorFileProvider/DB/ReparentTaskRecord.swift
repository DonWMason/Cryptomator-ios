//
//  ReparentTaskRecord.swift
//  CryptomatorFileProvider
//
//  Created by Philipp Schmid on 01.06.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import Foundation
import GRDB

struct ReparentTaskRecord: Decodable, FetchableRecord, TableRecord {
	static let databaseTableName = "reparentTasks"
	static let correspondingItemKey = "correspondingItem"
	static let sourceCloudPathKey = "sourceCloudPath"
	static let targetCloudPathKey = "targetCloudPath"
	static let oldParentIdKey = "oldParentId"
	static let newParentIdKey = "newParentId"
	let correspondingItem: Int64
	let sourceCloudPath: CloudPath
	let targetCloudPath: CloudPath
	let oldParentId: Int64
	let newParentId: Int64
}

extension ReparentTaskRecord: PersistableRecord {
	func encode(to container: inout PersistenceContainer) {
		container[ReparentTaskRecord.correspondingItemKey] = correspondingItem
		container[ReparentTaskRecord.sourceCloudPathKey] = sourceCloudPath
		container[ReparentTaskRecord.targetCloudPathKey] = targetCloudPath
		container[ReparentTaskRecord.oldParentIdKey] = oldParentId
		container[ReparentTaskRecord.newParentIdKey] = newParentId
	}
}

extension ReparentTaskRecord {
	static let itemMetadata = belongsTo(ItemMetadata.self, key: "metadata")
	var itemMetadata: QueryInterfaceRequest<ItemMetadata> {
		request(for: ReparentTaskRecord.itemMetadata)
	}
}
