//
//  Core.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 3/4/2024.
//

import Foundation
import UIKit

struct Core : Comparable, Hashable {
    enum Name : String, Hashable {
        case cytrus = "Cytrus", grape = "Grape", lychee = "Lychee"
    }
    
    enum Console : String, Codable, Hashable {
        case n3ds = "Nintendo 3DS", nds = "Nintendo DS", psx = "PlayStation 1"
        
        func buttonColors() -> [VirtualControllerButton.ButtonType : UIColor] {
            switch self {
            case .n3ds:
                [
                    .a : .systemRed,
                    .b : .systemYellow,
                    .x : .systemBlue,
                    .y : .systemGreen
                ]
            default:
                [
                    :
                ]
            }
        }
    }
    
    struct CoreDetails : Hashable {
        let name: Name
        let root: URL
        let supportedIdioms: [UIUserInterfaceIdiom]
        let supportedOrientations: [UIInterfaceOrientation]
    }
    
    let console: Console
    let details: CoreDetails
    var games: [AnyHashable]
    var missingFiles: [MissingFile]
    
    static func < (lhs: Core, rhs: Core) -> Bool {
        lhs.details.name.rawValue < rhs.details.name.rawValue
    }
}
