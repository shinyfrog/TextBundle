//
//  TextBundleWrapper+TextPack.swift
//  TextBundle
//
//  Created by Matteo Rattotti on 27/10/2020.
//

import Foundation
import Zip

extension TextBundleWrapper {
    @objc public convenience init(textPackURL: URL) throws {
        let temporaryDirectoryURL = try TextBundleWrapper.temporaryDirectoryURL()
        
        if !Zip.isValidFileExtension("textpack") {
            Zip.addCustomFileExtension("textpack")
        }
        
        try Zip.unzipFile(textPackURL, destination: temporaryDirectoryURL, overwrite: true, password: nil)
        
        if let unzippedURL = try FileManager.default.contentsOfDirectory(at: temporaryDirectoryURL, includingPropertiesForKeys: [], options: .skipsHiddenFiles).first {
            try self.init(url: unzippedURL)
        }
        else {
            throw TextBundleError.invalidBundleError("Invalid Textpack: can't unzip it")
        }
    }
    
    @objc public func writeTextPack(to url: URL) throws {
        var temporaryDirectoryURL = try TextBundleWrapper.temporaryDirectoryURL()
        temporaryDirectoryURL.appendPathComponent(url.deletingPathExtension().lastPathComponent)
        temporaryDirectoryURL.appendPathExtension("textbundle")
        
        try self.fileWrapper.write(to: temporaryDirectoryURL, options: [], originalContentsURL: nil)
        try Zip.zipFiles(paths: [temporaryDirectoryURL], zipFilePath: url, password: nil, compression: .NoCompression, progress: nil)
        try FileManager.default.removeItem(at: temporaryDirectoryURL)
    }
    
    class func temporaryDirectoryURL() throws -> URL {
        var temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        temporaryDirectoryURL.appendPathComponent(NSUUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: [:])
        return temporaryDirectoryURL
    }
}
