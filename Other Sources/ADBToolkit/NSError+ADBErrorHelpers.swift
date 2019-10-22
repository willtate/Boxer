//
//  File.swift
//  Boxer
//
//  Created by C.W. Betts on 10/22/19.
//  Copyright © 2019 Alun Bestor and contributors. All rights reserved.
//

import Foundation

@objc(ADBExceptionMangledFunctionType)
enum MangledFunctionType: Int {
    /// No detected mangling
    case none
    /// *C++* mangled function name
    case cPlusPlus
    /// *Swift* mangled name
    case swift
}

private let swiftPrefixes = ["_T", "$s", "_$S", "_T0"]
private let cxxPrefixes = ["_Z"]

extension NSException {
    @objc(possibleMangledTypeFromString:)
    class func possibleMangledType(from: String) -> MangledFunctionType {
        var trimFirst = false
        if from.first == "_" {
            trimFirst = true
        }
        for pref in swiftPrefixes {
            if from.starts(with: pref) {
                return .swift
            }
        }
        for pref in cxxPrefixes {
            if from.starts(with: pref) {
                return .cPlusPlus
            }
        }
        if trimFirst {
            var tmpFrom = from
            tmpFrom.removeFirst()
            return possibleMangledType(from: tmpFrom)
        }
        
        return .none
    }
    
    @objc class func demangledSwiftFunctionName(_ functionName: String) -> String? {
        //TODO: implement
        return nil
    }
}
