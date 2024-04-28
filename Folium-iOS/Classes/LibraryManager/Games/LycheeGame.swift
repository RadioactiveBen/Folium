//
//  LycheeGame.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 18/4/2024.
//

import Foundation

struct LycheeGame : Comparable, Hashable {
    let core: Core
    let fileURL: URL
    let size, title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(core)
        hasher.combine(fileURL)
        hasher.combine(size)
        hasher.combine(title)
    }
    
    static func < (lhs: LycheeGame, rhs: LycheeGame) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: LycheeGame, rhs: LycheeGame) -> Bool {
        lhs.title == rhs.title
    }
}
