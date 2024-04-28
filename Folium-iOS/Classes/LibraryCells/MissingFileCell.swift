//
//  MissingFileCell.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 23/1/2024.
//

import Foundation
import UIKit

class MissingFileCell : UICollectionViewCell {
    fileprivate var textLabel, secondaryTextLabel: UILabel!
    
    fileprivate var missingFile: MissingFile!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemRed.withAlphaComponent(0.09)
        //layer.borderWidth = 2
        // layer.borderColor = UIColor.systemRed.cgColor
        layer.cornerCurve = .continuous
        layer.cornerRadius = 15
        
        textLabel = .init()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        
        secondaryTextLabel = .init()
        secondaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(secondaryTextLabel)
        
        addConstraints([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            secondaryTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 4),
            secondaryTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            secondaryTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            secondaryTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
        
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(traitDidChange))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func traitDidChange() {
        layer.borderColor = (missingFile.fileDetails.importance == .optional ? UIColor.systemOrange : UIColor.systemRed).cgColor
    }
    
    func set(_ missingFile: MissingFile, for name: Core.Name) {
        self.missingFile = missingFile
        
        backgroundColor = missingFile.fileDetails.importance == .optional ? .systemOrange.withAlphaComponent(0.16) : .systemRed.withAlphaComponent(0.16)
        //layer.borderColor = (missingFile.fileDetails.importance == .optional ? UIColor.systemOrange : UIColor.systemRed).cgColor
        
        textLabel.attributedText = .init(string: missingFile.fileName, attributes: [
            .font : UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize),
            .foregroundColor : missingFile.fileDetails.importance == .optional ? UIColor.systemOrange : UIColor.systemRed
        ])
        
        secondaryTextLabel.attributedText = .init(string: missingFile.directory.path.components(separatedBy: "/").drop(while: { $0 != name.rawValue }).joined(separator: "/"), attributes: [
            .font : UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize),
            .foregroundColor : (missingFile.fileDetails.importance == .optional ? UIColor.systemOrange : UIColor.systemRed).withAlphaComponent(0.64)
        ])
    }
}
