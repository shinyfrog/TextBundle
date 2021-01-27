//
//  TextBundleWrapper.swift
//  TextBundle
//
//  Created by Matteo Rattotti on 22/10/2020.
//

import Foundation
import CoreServices

@objc open class TextBundleWrapper: NSObject {
        
    /// The plain text contents, read from text.* (whereas * is an arbitrary file extension)
    @objc public var text: String = ""
    
    ///  The version number of the file format. Version 2 (latest) is used as default.
    @objc public var version: UInt = 2
    
    /// The UTI of the text.* file.
    @objc public var type: String = TextBundleWrapper.UTTypeMarkdown
    
    /// Whether or not the bundle is a temporary container solely used for exchanging a document between applications. Defaults to “false”.
    @objc public var transient: Bool = false
    
    /// The bundle identifier of the application that created the file.
    @objc public var creatorIdentifier: String = Bundle.main.bundleIdentifier ?? ""

    /// Dictionary of application-specific information. Application-specific information must be stored inside a nested dictionary
    /// Use the provided utility methods (-applicationSpecificMetadata and -addApplicationSpecificMetadata:forKey:) to read write this.
    ///
    /// The dictionary is referenced by a key using the application bundle identifier (e.g. com.example.myapp).
    /// This dictionary should contain at least a version number to ensure backwards compatibility.
    ///
    /// Example:
    /// "com.example.myapp": {
    /// "version": 9,
    /// "customKey": "aCustomValue"
    /// }
    @objc public var metadata: [String: Any] = [:]
        
    
    /// Whether or not the bundle will try to prevent duplication of the same asset file (same name, same data)
    /// If this is set to true the bundle will not duplicate a file that already exist in the bundle.
    @objc public var preventAssetDuplication: Bool = false

    
    // MARK: - Init

    @objc public override init() {
        super.init()
    }
    
    
    /// Initialize a TextBundleWrapper instance from an URL
    /// - Parameters:
    ///   - url: file URL that the TextBundleWrapper is to represent
    ///   - options: options for reading the file. See FileWrapper.ReadingOptions for possible values.
    @objc public init(url: URL, options: FileWrapper.ReadingOptions = []) throws {
        super.init()
        try self.read(from: url, options: options)
    }

    
    /// Initialize a TextBundleWrapper instance from a NSFileWrapper
    /// - Parameter fileWrapper: The NSFileWrapper representing the TextBundle
    @objc public init(fileWrapper: FileWrapper) throws {
        super.init()
        try self.read(from: fileWrapper)
    }
    
    // MARK: - File Wrappers
    
    /// File wrapper represeting the whole TextBundle.
    @objc public var fileWrapper: FileWrapper {
        let filewrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        // Text
        filewrapper.addRegularFile(withContents: Data(self.text.utf8), preferredFilename: self.textFilename(for: self.type))
        
        // Info
        filewrapper.addRegularFile(withContents: self.jsonData(for: self.metadata)!, preferredFilename: TextBundleWrapper.TextBundleInfoFileName)
        
        // Assets
        if self.assetsFileWrapper.fileWrappers?.count ?? 0 > 0 {
            filewrapper.addFileWrapper(self.assetsFileWrapper)
        }
        
        return filewrapper
    }
    
    /// File wrapper containing all asset files referenced from the plain text file.
    @objc public lazy var assetsFileWrapper: FileWrapper = {
        var filewrapper = FileWrapper(directoryWithFileWrappers: [:])
        filewrapper.preferredFilename = TextBundleWrapper.TextBundleAssetsFileName
        
        return filewrapper
    }()

    // MARK: - Writing
    
    
    /// Writes the TextBundleWrapper content to a given file-system URL.
    /// - Parameters:
    ///   - url: URL of the file to which the TextBundleWrapper's contents are written
    ///   - options: flags for writing to the file located at url. See NSFileWrapperWritingOptions for possible values.
    ///   - originalContentsURL: The location of a previous revision of the contents being written.
    @objc public func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL?) throws {
        try self.fileWrapper.write(to: url, options: options, originalContentsURL: originalContentsURL)
    }
    
    // MARK: - Reading
    
    func read(from url: URL, options: FileWrapper.ReadingOptions = []) throws {
        let fileWrapper = try FileWrapper(url: url, options: options)
        try self.read(from: fileWrapper)
    }

    func read(from fileWrapper: FileWrapper) throws {
        // Loading a non-directory file wrapper is invalid
        if !fileWrapper.isDirectory {
            throw TextBundleError.invalidBundleError("Invalid Textbundle: not a bundle")
        }
        
        // Info
        if let infoFileWrapper = fileWrapper.fileWrappers?[TextBundleWrapper.TextBundleInfoFileName],
           let jsonData = infoFileWrapper.regularFileContents {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let metadata = json as? [String : Any] {
                self.metadata = metadata
                
                if let version = metadata[TextBundleWrapper.TextBundleVersion] as? UInt {
                    self.version = version
                }

                if let type = metadata[TextBundleWrapper.TextBundleType] as? String {
                    self.type = type
                }
                
                if let transient = metadata[TextBundleWrapper.TextBundleTransient] as? Bool {
                    self.transient = transient
                }

                if let creatorIdentifier = metadata[TextBundleWrapper.TextBundleCreatorIdentifier] as? String {
                    self.creatorIdentifier = creatorIdentifier
                }
            }
        }
        else {
            throw TextBundleError.invalidBundleError("Invalid Textbundle: info.json is missing")
        }
        
        // Text
        if let textFileWrapper = fileWrapper.fileWrappers?[self.textFilename(in: fileWrapper)], let data = textFileWrapper.regularFileContents {
            self.text = String(data: data, encoding: .utf8) ?? ""
        }
        else {
            throw TextBundleError.invalidBundleError("Invalid Textbundle: \(self.textFilename(for: type)) file is missing")
        }
        
        // Assets
        if let assetsFileWrapper = fileWrapper.fileWrappers?[TextBundleWrapper.TextBundleAssetsFileName] {
            self.assetsFileWrapper = assetsFileWrapper
        }
    }

    
    // MARK: - Text
    
    /// Finds the text.* file inside a textbundle filewrapper
    func textFilename(in fileWrapper: FileWrapper) -> String {
        var textFilename = "text.md"
        
        for (_, fw) in fileWrapper.fileWrappers ?? [:] {
            if let filename = fw.filename, filename.hasPrefix("text") {
                textFilename = filename
            }
        }
        
        return textFilename
    }
    
    /// Return the correct filename for the textbundle type (defaults to "text.md")
    func textFilename(for type: String) -> String {
        if let ext = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension) {
            return "text." + (ext.takeRetainedValue() as String)
        }
         
        return "text.md"
    }
    
    // MARK: - Assets
    
    
    ///  Return the filewrapper represeting an asset or nil if there is no asset named with filename
    /// - Parameter assetFilename: A filename in the asset/ folder
    /// - Returns: A NSFilewrapper represeting filename or nil it the file doesn't exist
    @objc public func fileWrapper(for assetFilename: String) -> FileWrapper? {
        for (_, fw) in self.assetsFileWrapper.fileWrappers ?? [:] {
            if fw.filename == assetFilename || fw.preferredFilename == assetFilename {
                return fw
            }
        }
        
        return nil
    }

    
    /// Add a NSFileWrapper to the TextBundleWrapper's assetFileWrapper.
    /// If a file have the same name of an exiting file the name will be updated to avoid conflicts.
    /// With `preventAssetDuplication` set as `true` if the name and file content are the same this method does nothing.
    /// - Parameter filewrapper:  A NSFileWrapper to add to the TextBundleWrapper's assets
    /// - Returns: The updated filename of the added asset
    @objc public func addAssetFileWrapper(_ filewrapper: FileWrapper) -> String? {
        guard let originalFilename = filewrapper.filename ?? filewrapper.preferredFilename,
              let currentFilenames = self.assetsFileWrapper.fileWrappers?.keys else {
            return nil
        }

        var filename = originalFilename
        var filenameCount = 1
        var shouldAddFileWrapper = true
        
        while currentFilenames.contains(filename) {
            // Same filename and same data, we can skip adding this file
            if self.preventAssetDuplication, let existingFileWrapper = self.assetsFileWrapper.fileWrappers?[filename],
               filewrapper.regularFileContents == existingFileWrapper.regularFileContents {
                shouldAddFileWrapper = false
                break
            }
            
            // Same filename, different data, changing the name
            filenameCount += 1
            var url = URL(fileURLWithPath: originalFilename)
            let fileExtension = url.pathExtension
            url.deletePathExtension()
            filename = url.lastPathComponent + " \(filenameCount)." + fileExtension
        }
        
        if shouldAddFileWrapper {
            // If we already have this specific filewrapper we just add a new one with the same content
            if self.assetsFileWrapper.fileWrappers?.values.contains(filewrapper) ?? false {
                self.assetsFileWrapper.addRegularFile(withContents: filewrapper.regularFileContents!, preferredFilename: filename)
            }
            // Adding the filewrapper with the correct filename
            else {
                filewrapper.filename = filename
                filewrapper.preferredFilename = filename

                filename = self.assetsFileWrapper.addFileWrapper(filewrapper)
            }
        }
        
        return filename
    }
    
    
    
    // MARK: - Metadata
        
    @objc public func applicationSpecificMetadata(for identifier: String?) -> [String: Any]? {
        let key = identifier ?? Bundle.main.bundleIdentifier ?? ""
        return self.metadata[key] as? [String: Any]
    }
    
    @objc public func addApplicationSpecificMetadata(_ metadata: Any, for key: String, identifier: String?) {
        var applicationSpecificMetadata = self.applicationSpecificMetadata(for: identifier) ?? [:]
        applicationSpecificMetadata[key] = metadata

        let id = identifier ?? Bundle.main.bundleIdentifier ?? ""
        self.metadata[id] = applicationSpecificMetadata
    }
    
    @objc public func removeApplicationSpecificMetadata(for key: String, identifier: String?) {
        var applicationSpecificMetadata = self.applicationSpecificMetadata(for: identifier) ?? [:]
        applicationSpecificMetadata.removeValue(forKey: key)
        
        let id = identifier ?? Bundle.main.bundleIdentifier ?? ""
        self.metadata[id] = applicationSpecificMetadata
    }

    func jsonData(for metadata: [String: Any]) -> Data? {
        var allMetadata = metadata
        allMetadata[TextBundleWrapper.TextBundleVersion] = self.version
        allMetadata[TextBundleWrapper.TextBundleType] = self.type
        allMetadata[TextBundleWrapper.TextBundleTransient] = self.transient
        allMetadata[TextBundleWrapper.TextBundleCreatorIdentifier] = self.creatorIdentifier
        
        let json = try? JSONSerialization.data(withJSONObject: allMetadata, options: .prettyPrinted)
        return json
    }
    
    // MARK: - File type
    
    
    /// Returns whether a UTI type conforms to the "org.textbundle.package" type identifier
    /// - Parameter type: A uniform type identifier to compare.
    @objc public class func typeConformToTextBundle(_ type: NSString) -> Bool {
        return UTTypeConformsTo(type as CFString, TextBundleWrapper.UTTypeTextBundle as CFString)
    }

    /// Returns whether a UTI type conforms to the "org.textbundle.compressed" type identifier
    /// - Parameter type: A uniform type identifier to compare.
    @objc public class func typeConformToTextPack(_ type: NSString) -> Bool {
        return UTTypeConformsTo(type as CFString, TextBundleWrapper.UTTypeTextPack as CFString)
    }
    
    
    /// Returns whether an URL conforms to the "org.textbundle.package" type identifier
    /// - Parameter url: The URL which uniform type identifier should be check
    @objc public class func urlConformsToTextBundle(_ url: URL) -> Bool {
        return self.filenameExtension(url.pathExtension, isValidForType: TextBundleWrapper.UTTypeTextBundle as CFString)
    }

    /// Returns whether an URL conforms to the "org.textbundle.compressed" type identifier
    /// - Parameter url: The URL which uniform type identifier should be check
    @objc public class func urlConformsToTextPack(_ url: URL) -> Bool {
        return self.filenameExtension(url.pathExtension, isValidForType: TextBundleWrapper.UTTypeTextPack as CFString)
    }
    
    class func filenameExtension(_ filenameExtension: String?, isValidForType type: CFString) -> Bool {
        if let filenameExtension = filenameExtension,
           !filenameExtension.isEmpty,
           let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, filenameExtension as CFString, nil) {
            return UTTypeConformsTo(uti.takeRetainedValue(), type)
        }
        return false
    }
}

// MARK: - Constants

@objc extension TextBundleWrapper {
    // Filenames constants
    @objc static let TextBundleInfoFileName = "info.json"
    @objc static let TextBundleAssetsFileName = "assets"

    // UTI constants
    @objc public static let UTTypeMarkdown = "net.daringfireball.markdown"
    @objc public static let UTTypeTextBundle = "org.textbundle.package"
    @objc public static let UTTypeTextPack = "org.textbundle.compressed"
    
    // Metadata constants
    @objc static let TextBundleVersion = "version"
    @objc static let TextBundleType = "type"
    @objc static let TextBundleTransient = "transient"
    @objc static let TextBundleCreatorIdentifier = "creatorIdentifier"
}

enum TextBundleError: Error {
    case invalidBundleError(String)    
}
