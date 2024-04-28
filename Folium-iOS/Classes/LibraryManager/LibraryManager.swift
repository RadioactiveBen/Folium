//
//  LibraryManager.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 1/18/24.
//

import Cytrus
import Foundation
import UIKit

class DirectoriesManager {
    static let shared = DirectoriesManager()
    
    func directories() -> [String : [String : [String : MissingFile.FileDetails]]] {
        [
            "Cytrus" : [
                "cache" : [:],
                "cheats" : [:],
                "config" : [:],
                "dump" : [:],
                "external_dlls" : [:],
                "load" : [:],
                "log" : [:],
                "nand" : [:],
                "roms" : [:],
                "sdmc" : [:],
                "shaders" : [:],
                "states" : [:],
                "sysdata" : [
                    "aes_keys.txt" : .init(importance: .required, isFromSystem: true)
                ]
            ],
            "Grape" : [
                "config" : [:],
                "roms" : [:],
                "saves" : [:],
                "sysdata" : [
                    "bios7.bin" : .init(importance: .required, isFromSystem: true),
                    "bios9.bin" : .init(importance: .required, isFromSystem: true),
                    "firmware.bin" : .init(importance: .required, isFromSystem: true),
                    "gba_bios.bin" : .init(importance: .optional, isFromSystem: true),
                    "sdcard.img" : .init(importance: .optional, isFromSystem: false)
                ]
            ]/*,
            "Lychee" : [
                "roms" : [:],
                "sysdata" : [
                    "bios.bin" : .init(importance: .required, isFromSystem: true)
                ]
            ]*/
        ]
    }
    
    func createMissingDirectoriesInDocumentsDirectory() throws {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try directories().forEach { directory, subdirectories in
            let coreDirectory = documentsDirectory.appendingPathComponent(directory, conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: coreDirectory.path) {
                try FileManager.default.createDirectory(at: coreDirectory, withIntermediateDirectories: false)
                
                try subdirectories.forEach { subdirectory, files in
                    let coreSubdirectory = coreDirectory.appendingPathComponent(subdirectory, conformingTo: .folder)
                    if !FileManager.default.fileExists(atPath: coreSubdirectory.path) {
                        try FileManager.default.createDirectory(at: coreSubdirectory, withIntermediateDirectories: false)
                    }
                }
            } else {
                try subdirectories.forEach { subdirectory, files in
                    let coreSubdirectory = coreDirectory.appendingPathComponent(subdirectory, conformingTo: .folder)
                    if !FileManager.default.fileExists(atPath: coreSubdirectory.path) {
                        try FileManager.default.createDirectory(at: coreSubdirectory, withIntermediateDirectories: false)
                    }
                }
            }
        }
    }
    
    func scanDirectoriesForRequiredFiles(for core: inout Core) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let directory = directories().first(where: { $0.key == core.details.name.rawValue }) else {
            return
        }
        
        directory.value.forEach { subdirectory, fileNames in
            let coreSubdirectory = documentsDirectory.appendingPathComponent(directory.key, conformingTo: .folder)
                .appendingPathComponent(subdirectory, conformingTo: .folder)
            fileNames.forEach { (fileName, fileDetails) in
                if !FileManager.default.fileExists(atPath: coreSubdirectory.appendingPathComponent(fileName, conformingTo: .fileURL).path) {
                    core.missingFiles.append(.init(coreName: core.details.name, directory: coreSubdirectory,
                                                   fileDetails: fileDetails, fileName: fileName))
                }
            }
        }
    }
}

enum LibraryManagerError : Error {
    case invalidEnumerator, invalidURL
}

class LibraryManager {
    static let shared = LibraryManager()
    
    func library() throws -> [Core] {
        func romsDirectoryCrawler(for coreName: Core.Name) throws -> [URL] {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            guard let enumerator = FileManager.default.enumerator(at: documentsDirectory.appendingPathComponent(coreName.rawValue, conformingTo: .folder)
                .appendingPathComponent("roms", conformingTo: .folder), includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                throw LibraryManagerError.invalidEnumerator
            }
            
            var urls: [URL] = []
            try enumerator.forEach { element in
                switch element {
                case let url as URL:
                    let attributes = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if let isRegularFile = attributes.isRegularFile, isRegularFile {
                        switch coreName {
                        case .cytrus:
                            if ["3ds", "3dsx", "app", "cci", "cxi"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
                        case .grape:
                            if ["gba", "nds"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
                        case .lychee:
                            if ["bin", "iso"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
            
            return urls
        }
        
        func games(from urls: [URL], for core: inout Core) {
            switch core.details.name {
            case .cytrus:
                core.games = urls.reduce(into: [CytrusGame]()) { partialResult, element in
                    let information = Cytrus.shared.information(for: element)
                    
                    let game = CytrusGame(core: core, fileURL: element, imageData: information.iconData,
                                          publisher: information.publisher,
                                          title: information.title)
                    partialResult.append(game)
                }
            case .grape:
                core.games = urls.reduce(into: [GrapeGame]()) { partialResult, element in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: element.path)
                    
                    let fileSize = attributes?[.size] as? Int64 ?? 0
                    
                    let byteFormatter = ByteCountFormatter()
                    byteFormatter.allowedUnits = [.useKB, .useMB]
                    byteFormatter.countStyle = .file
                    
                    let isGBA = element.pathExtension.lowercased() == "gba"
                    let title = element.lastPathComponent.replacingOccurrences(of: isGBA ? ".gba" : ".nds", with: "")
                    
                    let game = GrapeGame(core: core, fileURL: element, isGBA: isGBA, size: byteFormatter.string(fromByteCount: fileSize), title: title)
                    partialResult.append(game)
                }
            case .lychee:
                core.games = urls.reduce(into: [LycheeGame]()) { partialResult, element in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: element.path)
                    
                    let fileSize = attributes?[.size] as? Int64 ?? 0
                    
                    let byteFormatter = ByteCountFormatter()
                    byteFormatter.allowedUnits = [.useKB, .useMB]
                    byteFormatter.countStyle = .file
                    
                    let title = element.lastPathComponent.replacingOccurrences(of: "bin", with: "")
                        .replacingOccurrences(of: "iso", with: "")
                    
                    let game = LycheeGame(core: core, fileURL: element, size: byteFormatter.string(fromByteCount: fileSize), title: title)
                    partialResult.append(game)
                }
            default:
                break
            }
        }
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var cytrusCore = Core(console: .n3ds, details: .init(name: .cytrus,
                                                             root: directory.appendingPathComponent(Core.Name.cytrus.rawValue, conformingTo: .folder),
                                                             supportedIdioms: [.pad, .phone],
                                                             supportedOrientations: [.portrait]), games: [], missingFiles: [])
        games(from: try romsDirectoryCrawler(for: .cytrus), for: &cytrusCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &cytrusCore)
        
        var grapeCore = Core(console: .nds, details: .init(name: .grape,
                                                           root: directory.appendingPathComponent(Core.Name.grape.rawValue, conformingTo: .folder),
                                                           supportedIdioms: [.pad, .phone],
                                                           supportedOrientations: [.portrait, .landscapeLeft, .landscapeRight]), games: [], missingFiles: [])
        games(from: try romsDirectoryCrawler(for: .grape), for: &grapeCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &grapeCore)
        
        var lycheeCore = Core(console: .psx, details: .init(name: .lychee,
                                                           root: directory.appendingPathComponent(Core.Name.lychee.rawValue, conformingTo: .folder),
                                                           supportedIdioms: [.pad, .phone],
                                                           supportedOrientations: [.portrait, .landscapeLeft, .landscapeRight]), games: [], missingFiles: [])
        games(from: try romsDirectoryCrawler(for: .lychee), for: &lycheeCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &lycheeCore)
        
        return [cytrusCore, grapeCore]
    }
}
