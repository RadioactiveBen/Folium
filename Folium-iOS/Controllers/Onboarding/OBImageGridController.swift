//
//  OBImageGridController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 23/4/2024.
//

import Foundation
import UIKit

class OBImageGridController : UICollectionViewController {
    fileprivate var dataSource: UICollectionViewDiffableDataSource<String, Image>! = nil
    fileprivate var snapshot: NSDiffableDataSourceSnapshot<String, Image>! = nil
    
    struct Image : Hashable, Identifiable {
        var id = UUID()
        let color: UIColor?
        let systemName: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(systemName)
        }
    }
    
    class ImageGridCell : UICollectionViewCell {
        fileprivate var imageView: UIImageView! = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            imageView = .init(frame: .zero)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            contentView.addSubview(imageView)
            addConstraints([
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    fileprivate var color: UIColor?
    fileprivate var systemNames: [String]
    init(color: UIColor?, systemNames: [String]) {
        self.color = color
        self.systemNames = systemNames
        super.init(collectionViewLayout: Layouts.shared.images())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        view.backgroundColor = .secondarySystemBackground
        
        let cellRegistration = UICollectionView.CellRegistration<ImageGridCell, Image> { cell, indexPath, itemIdentifier in
            if indexPath.item % 2 == 0 {
                cell.imageView.image = .init(systemName: itemIdentifier.systemName) ?? .init(systemName: "questionmark.square.dashed")
                cell.imageView.tintColor = self.color?.withAlphaComponent(0.16) ?? .tertiarySystemBackground
            }
        }
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        snapshot = .init()
        snapshot.appendSections(["Images"])
        
        for _ in 0...(traitCollection.userInterfaceIdiom == .pad ? 400 : 200) {
            guard let name = systemNames.randomElement() else {
                return
            }
            
            snapshot.appendItems([.init(color: color, systemName: name)], toSection: "Images")
        }
        
        Task {
            await dataSource.apply(snapshot)
        }
    }
}
