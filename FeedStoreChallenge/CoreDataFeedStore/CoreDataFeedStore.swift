//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by John Roque Jorillo on 2/27/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
	
	public init() {}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		completion(.empty)
	}
}
