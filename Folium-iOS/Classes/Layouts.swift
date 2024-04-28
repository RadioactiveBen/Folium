//
//  Layouts.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 17/4/2024.
//

import Foundation
import UIKit

class Layouts {
    static let shared = Layouts()
    
    func images() -> UICollectionViewCompositionalLayout {
        .init { _, layoutEnvironment in
            let itemsInGroup: CGFloat = layoutEnvironment.traitCollection.userInterfaceIdiom == .pad ? 13 : 9
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1 / itemsInGroup), heightDimension: .fractionalWidth(1 / itemsInGroup))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(10)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
            section.interGroupSpacing = 10
            return section
        }
    }
    
    func library(_ cores: [Core]) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 20
        
        return .init(sectionProvider: { sectionIndex, _ in
            let iPad = UIDevice.current.userInterfaceIdiom == .pad
            let itemsInGroup: CGFloat = if UIApplication.shared.statusBarOrientation == .portrait {
                iPad ? 6 : 3
            } else {
                iPad ? 8 : 5
            }
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1 / itemsInGroup), heightDimension: .estimated(300))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
            let group: NSCollectionLayoutGroup = if #available(iOS 17, *) {
                .horizontal(layoutSize: groupSize, repeatingSubitem: item, count: Int(itemsInGroup))
            } else if #available(iOS 16, *) {
                .horizontal(layoutSize: groupSize, repeatingSubitem: item, count: Int(itemsInGroup))
            } else {
                .horizontal(layoutSize: groupSize, subitem: item, count: Int(itemsInGroup))
            }
            
            group.interItemSpacing = .fixed(20)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                      elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            ]
            section.contentInsets = .init(top: 0, leading: 20, bottom: sectionIndex == cores.count ? 20 : 0, trailing: 20)
            section.interGroupSpacing = 20
            return section
        }, configuration: configuration)
    }
    
    func missingFiles() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 20
        
        return .init(sectionProvider: { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            group.interItemSpacing = .fixed(20)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                      elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            ]
            section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.interGroupSpacing = 20
            
            return section
        }, configuration: configuration)
    }
}
