//
//  ADBSwiftHelpers.swift
//  Boxer
//
//  Created by C.W. Betts on 12/9/19.
//  Copyright © 2019 Alun Bestor and contributors. All rights reserved.
//

import Foundation

extension ADBBinCueImage {
    /// Returns `true` if the specified path contains a parseable cue file, `false` otherwise.
    /// Throws an error if there is a problem accessing the file.
    open class func isCue(at cueURL: URL) throws -> Bool {
        var outError: NSError? = nil
        let isACue = __isCue(at: cueURL, error: &outError)
        if !isACue, let err = outError {
            throw err
        }
        return isACue
    }

}
