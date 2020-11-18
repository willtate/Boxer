//
//  URL+ADBFilesystemHelpers.swift
//  Boxer
//
//  Created by C.W. Betts on 11/9/20.
//  Copyright © 2020 Alun Bestor and contributors. All rights reserved.
//

import Foundation

extension URL {
    
     /// Returns a path for this URL that's relative to the specified file URL,
     /// producing the following results:
     /// - **/foo/bar** relative to **/** becomes `@"foo/bar"`
     /// - **/foo/bar** relative to **/foo/bar** becomes `@""`
     /// - **/foo/bar** relative to **/foo** becomes `@"bar"`
     /// - **/foo/bar** relative to **/foo/baz** becomes `@"../bar"`
     /// - **/foo/bar** relative to **/baz** becomes `@"../foo/bar"`
     /// - **/foo/bar** relative to **/baz/bla** becomes `@"../../foo/bar"`
     ///
     /// That is, the resulting string can be appended to the base URL with `URLByAppendingPathComponent:` to form an absolute URL to the original resource.
    func pathRelative(to baseURL1: URL) -> String {
        //First, standardize both paths.
        let baseURL     = baseURL1.standardizedFileURL;
        let originalURL = self.standardizedFileURL
        
        //Optimisation: if the original URL is already inside the base URL,
        //we can get the relative URL just by snipping off the front of the string.
        if originalURL.isBased(in: baseURL) {
            let prefixLength = baseURL.path.count
            let originalPath = originalURL.path
            let hi = originalPath.index(originalPath.startIndex, offsetBy: prefixLength)
            var relativePath = originalPath[hi...]
            
            //Check if there's a stray slash on the front and remove that also.
            if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
            }
            return String(relativePath)
        }
        //Otherwise, we need to go more in-depth and look at individual path components.
        else {
            let components      = originalURL.pathComponents;
            let baseComponents  = baseURL.pathComponents;
            let numInOriginal   = components.count;
            let numInBase       = baseComponents.count;
            var from1 = 0
            let upTo = min(numInBase, numInOriginal);
            
            //Skip over any common prefixes
            for from in 0 ..< upTo {
                if components[from] != baseComponents[from] {
                    break;
                }
                from1 += 1
            }
            
            let stepsBack = numInBase - from1
            var relativeComponents = [String]()
            relativeComponents.reserveCapacity(stepsBack + numInOriginal - from1)

            //First, add the steps to get back to the first common directory
            for _ in 0 ..< stepsBack {
                relativeComponents.append("..")
            }
            //Then, add the steps from there to the original path
            relativeComponents.append(contentsOf: components[from1 ..< (numInOriginal - from1)])
            
            return NSString.path(withComponents: relativeComponents)
        }

    }
    
    /// Whether this URL has the specified file URL as an ancestor.
    func isBased(in baseURL: URL?) -> Bool {
        guard let baseURL = baseURL else {
            return false;
        }
        
        var basePath = baseURL.standardizedFileURL.path
        var originalPath = self.standardizedFileURL.path
        
        if originalPath == basePath {
            return true
        }
        
        if !basePath.hasSuffix("/") {
            basePath += "/"
        }
        
        if !originalPath.hasSuffix("/") {
            originalPath += "/"
        }
        
        return originalPath.hasPrefix(basePath)
        
    }
    
    /// Returns an array containing this URL and every parent directory leading back
    /// to the root.
    ///
    /// An analogue for `-[NSString pathComponents:]`
    var componentURLs: [URL] {
        //Build an array of complete paths for each component of this URL
        var components = [URL]()
        components.reserveCapacity(10)
        
        let currentURL = self
        var parentURL: URL? = nil
        while true {
            //NOTE: we insert each component in reverse order
            components.insert(currentURL, at: 0)
            parentURL = currentURL.deletingLastPathComponent()
            //We've reached the root once URLByDeletingLastPathComponent
            //returns an identical URL
            if parentURL == currentURL {
                break
            }
        }
        
        return components
    }
    
    /// An analogue for `-[NSString stringsByAppendingPaths:]`
    @inlinable func urls(byAppendingPaths paths: [String]) -> [URL] {
        return paths.map ({self.appendingPathComponent($0)})
    }
}


extension URL {
    /// Returns the value for the specified resource property.
    ///
    /// - returns: `nil` if the property cannot be retrieved for any reason.
    ///
    /// This is just a simpler calling syntax for `-[NSURL getResourceValue:forKey:error:]`
    /// for when you don't care about failure reasons.
    func resourceValue(forKey key: URLResourceKey) -> Any? {
        do {
            var value: AnyObject?
            try (self as NSURL).getResourceValue(&value, forKey: key)
            return value
        } catch {
            return nil
        }
    }

    
    /// Returns the localized display name of the file: i.e., the value of
    /// `NSURLLocalizedNameKey`.
    var localizedName: String? {
        resourceValue(forKey: .localizedNameKey) as? String
    }

    
    /// Returns whether this URL represents a directory: i.e. the value
    /// of `NSURLIsDirectoryKey`.
    var isDirectory: Bool {
        guard let hi = resourceValue(forKey: .isDirectoryKey) as? Bool else {
            return false
        }
        return hi
    }

}

extension URL {
    /// Returns the recommended file extension to use for files of the specified type.
    /// Analogous to `-[NSWorkspace preferredExtensionForFileType:]`.
    static func preferredExtension(forFileType UTI: String) -> String? {
        guard let extensionForUTI = UTTypeCopyPreferredTagWithClass(UTI as NSString, kUTTagClassFilenameExtension)?.takeRetainedValue() else {
            return nil
        }
        return extensionForUTI as String
    }
    
    /// Returns the UTI most applicable to files with the specified extension.
    static func fileType(forExtension ext: String) -> String? {
        let UTIForExtension = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                    ext as NSString,
            nil)?.takeRetainedValue()
        guard let theUTI = UTIForExtension as String? else {
            return nil
        }
        return theUTI
    }
    
    /// Returns all of the UTIs that use the specified extension.
    static func fileTypes(forExtension ext: String) -> [String]? {
        guard let toRet = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, ext as NSString, nil)?.takeRetainedValue() else {
            return nil
        }
        return toRet as NSArray as? [String]
    }

    /// Returns the UTI of the file at this URL, or `nil` if this could not be determined.
    var typeIdentifier: String? {
        guard let res = try? resourceValues(forKeys: [.typeIdentifierKey]), let theType = res.typeIdentifier else {
            let pe = pathExtension
            // Attempt to return a UTI based solely on our file extension instead.
            if pe.count > 0 {
                return URL.fileType(forExtension: pe)
            } else {
                return nil
            }
        }
        
        return theType
    }
    
    /// Returns `true` if the Uniform Type Identifier for the file at this URL is
    /// equal to or inherits from the specified UTI, or if the URL has a path
    /// extension that would be suitable for the specified UTI.
    func conformsTo(fileType comparisonUTI: String) -> Bool {
        let reportedUTI = typeIdentifier
        if let reportedUTI = reportedUTI, UTTypeConformsTo(reportedUTI as CFString, comparisonUTI as CFString) {
            return true
        }
        
        // Also check if the file extension is suitable for the given type, in case
        // an overly generic UTI definition was returned. This has been observed to
        // happen with folder-derived UTIs in 10.5-10.8, where `NSURLTypeIdentifierKey`
        // reports `public.folder` as the UTI when the extension conforms to a more
        // specific UTI.
        let ext = pathExtension
        if ext.count != 0 {
            let utiForExt = URL.fileType(forExtension: ext)
            if let utiForExt = utiForExt, utiForExt != reportedUTI, UTTypeConformsTo(utiForExt as CFString, comparisonUTI as CFString) {
                return true
            }
        }
        
        return false
    }
    
    /// Given a set of Uniform Type Identifiers, returns the first one to which this
    /// URL conforms, or `nil` if it doesn't match any of them.
    func matchingFileTypes(_ UTIs: Set<String>) -> String? {
        let reportedUTI = typeIdentifier
        if let reportedUTI = reportedUTI {
            for comparisonUTI in UTIs {
                if UTTypeConformsTo(reportedUTI as NSString, comparisonUTI as NSString) {
                    return comparisonUTI
                }
            }
        }
        
        // If we couldn't match against the URL's reported UTI, check again against
        // the UTI for the URL's path extension. (See note under `conformsToUTI:`
        // for details on when this is necessary.)
        let ext = self.pathExtension
        if ext.count != 0 {
            if let UTIForExtension = URL.fileType(forExtension: ext),
                UTIForExtension != reportedUTI {
                for comparisonUTI in UTIs {
                    if UTTypeConformsTo(UTIForExtension as NSString, comparisonUTI as NSString) {
                        return comparisonUTI
                    }
                }
            }
        }

        return nil
    }
}
