//
//  OBBaseController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 23/4/2024.
//

import Foundation
import UIKit

class OBBaseController : UIViewController {
    struct OBStep {
        let systemNames: [String]
        let text, secondaryText: String
        let buttonText: String
        
        let buttonAction: UIActionHandler
        let buttonColor: UIColor?
    }
    
    fileprivate var bottomView: UIView!
    
    fileprivate var button: UIButton!
    fileprivate var textLabel, secondaryTextLabel: UILabel!
    
    fileprivate var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }
    
    fileprivate var step: OBStep
    init(step: OBStep) {
        self.step = step
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        // MARK: START: Bottom View
        bottomView = .init()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = .systemBackground
        view.addSubview(bottomView)
        // MARK: END: Bottom View
        
        // MARK: START: Collection View
        let collectionViewController = OBImageGridController(color: step.buttonColor, systemNames: step.systemNames)
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(collectionViewController)
        view.addSubview(collectionViewController.view)
        view.insertSubview(collectionViewController.view, belowSubview: bottomView)
        collectionViewController.didMove(toParent: self)
        // MARK: END: Collection View
        
        // MARK: START: Button
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = .init(step.buttonText, attributes: .init([
            .font : UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize),
            .foregroundColor : self.step.buttonColor == nil ? self.isDarkMode ? UIColor.black : UIColor.white : UIColor.white
        ]))
        configuration.baseBackgroundColor = self.step.buttonColor ?? (self.isDarkMode ? .white : .black)
        configuration.buttonSize = .large
        configuration.cornerStyle = .large
        
        button = .init(configuration: configuration, primaryAction: .init(handler: self.step.buttonAction))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configurationUpdateHandler = { button in
            guard var configuration = button.configuration else {
                return
            }
            
            configuration.attributedTitle = .init(self.step.buttonText, attributes: .init([
                .font : UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize),
                .foregroundColor : self.step.buttonColor == nil ? self.isDarkMode ? UIColor.black : UIColor.white : UIColor.white
            ]))
            configuration.baseBackgroundColor = self.step.buttonColor ?? (self.isDarkMode ? .white : .black)
            button.configuration = configuration
        }
        bottomView.addSubview(button)
        // MARK: END: Button
        
        // MARK: START: Secondary Label
        secondaryTextLabel = .init()
        secondaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryTextLabel.font = .preferredFont(forTextStyle: .body)
        secondaryTextLabel.numberOfLines = 9
        secondaryTextLabel.text = step.secondaryText // "Beautifully designed, high performing multi-system emulation in the palm of your hands"
        secondaryTextLabel.textAlignment = .center
        secondaryTextLabel.textColor = .secondaryLabel
        bottomView.addSubview(secondaryTextLabel)
        // MARK: END: Secondary Label
        
        // MARK: START: Label
        textLabel = .init()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 17, *) {
            textLabel.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .extraLargeTitle).pointSize)
        } else {
            textLabel.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize)
        }
        textLabel.text = step.text // "Folium"
        textLabel.textAlignment = .center
        textLabel.textColor = .label
        bottomView.addSubview(textLabel)
        // MARK: END: Label
        
        view.addConstraints([
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            collectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            button.leadingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            button.bottomAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.trailingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            secondaryTextLabel.leadingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            secondaryTextLabel.bottomAnchor.constraint(equalTo: button.safeAreaLayoutGuide.topAnchor, constant: -80),
            secondaryTextLabel.trailingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            textLabel.topAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.topAnchor, constant: 40),
            textLabel.leadingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textLabel.bottomAnchor.constraint(equalTo: secondaryTextLabel.safeAreaLayoutGuide.topAnchor, constant: -20),
            textLabel.trailingAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
        
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(userInterfaceStyleDidChange))
        }
    }
    
    @objc func userInterfaceStyleDidChange() {
        button.setNeedsUpdateConfiguration()
    }
}

