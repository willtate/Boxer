//
//  URL+ADBAliasHelpers.swift
//  Boxer
//
//  Created by C.W. Betts on 11/10/20.
//  Copyright © 2020 Alun Bestor and contributors. All rights reserved.
//

import Foundation

extension URL {
    /// Returns 10.6 bookmark data converted from the specified Carbon alias record.
    /// Throws if conversion failed.
    static func bookmarkData(fromAliasRecord aliasRecord: Data) throws -> Data {
        guard let bookmarkDataRef = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, aliasRecord as NSData)?.takeRetainedValue() else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return bookmarkDataRef as Data
    }
    
    /// Returns a URL resolved from the specified Finder alias record.
    /// Directly equivalent to `+[NSURL URLByResolvingBookmarkData:options:relativeToURL:bookmarkDataIsStale:error:]`.
    public init(resolvingAliasRecord aliasRecord: Data, options: NSURL.BookmarkResolutionOptions = [], relativeTo relativeURL: URL? = nil, bookmarkDataIsStale isStale: inout Bool) throws {
        let bookmarkData = try URL.bookmarkData(fromAliasRecord: aliasRecord)
        self = try URL(resolvingBookmarkData: bookmarkData, options: options, relativeTo: relativeURL, bookmarkDataIsStale: &isStale)
    }
}
