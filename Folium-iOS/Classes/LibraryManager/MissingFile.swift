//
//  MissingFile.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 3/4/2024.
//

import Foundation

struct MissingFile : Hashable {
    struct FileDetails : Hashable {
        enum FileImportance : String, CustomStringConvertible {
            case optional = "Optional", required = "Required"
            
            var description: String {
                rawValue
            }
        }
        
        let importance: FileImportance
        let isFromSystem: Bool
    }
    
    let coreName: Core.Name
    let directory: URL
    var fileDetails: FileDetails
    let fileName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coreName)
        hasher.combine(directory)
        hasher.combine(fileDetails)
        hasher.combine(fileName)
    }
}
