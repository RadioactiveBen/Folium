//
//  LibraryController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 23/1/2024.
//

import Foundation
import Grape
import UIKit

class LibraryController : UICollectionViewController {
    var dataSource: UICollectionViewDiffableDataSource<AnyHashable, AnyHashable>! = nil
    var snapshot: NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>! = nil
    
    var cores: [Core]
    
    init(collectionViewLayout layout: UICollectionViewLayout, cores: [Core]) {
        self.cores = cores
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Library"
        view.backgroundColor = .systemBackground
        
        
        let listOfSupportedDevices: [String] = [
            "iPhone14,2",
            "iPhone14,3",
            "iPhone14,4",
            "iPhone14,5",
            "iPhone14,6",
            "iPhone14,7",
            "iPhone14,8",
            "iPhone15,2",
            "iPhone15,3",
            "iPhone15,4",
            "iPhone15,5",
            "iPhone16,1",
            "iPhone16,2"
        ]
        
        if traitCollection.userInterfaceIdiom == .phone && !listOfSupportedDevices.contains(Utsname().machine) && !UserDefaults.standard.bool(forKey: "acknowledgedUnsupported") {
            let unsupportedController = OBBaseController(step: .init(systemNames: [
                "exclamationmark.triangle",
                "exclamationmark.triangle.fill",
                "exclamationmark.octagon",
                "exclamationmark.octagon.fill"
            ], text: "Limited Support", secondaryText: "Your device may not support all cores resulting in crashes and unexpected issues, this is a hardware restriction, not software", buttonText: "Acknowledge", buttonAction: { _ in
                UserDefaults.standard.setValue(true, forKey: "acknowledgedUnsupported")
                UIApplication.topViewController()?.dismiss(animated: true)
            }, buttonColor: .systemRed))
            unsupportedController.isModalInPresentation = true
            if let sheetPresentationController = unsupportedController.sheetPresentationController {
                sheetPresentationController.detents = [.large()]
            }
            self.present(unsupportedController, animated: true)
        }
        
        
        let refreshControl = UIRefreshControl(frame: .zero, primaryAction: .init(handler: { action in
            guard let refreshControl = action.sender as? UIRefreshControl else {
                return
            }
            
            refreshControl.beginRefreshing()
            Task {
                try await self.updateDataSource(true)
                refreshControl.endRefreshing()
            }
        }))
        collectionView.refreshControl = refreshControl
        
        let cytrusGameCellRegistration = UICollectionView.CellRegistration<GameCell, CytrusGame> { cell, indexPath, itemIdentifier in
            if let image = itemIdentifier.imageData.decodeRGB565(width: 48, height: 48) {
                cell.imageView.image = image
            } else {
                cell.missingImageView.image = .init(systemName: "slash.circle")
            }
            cell.set(itemIdentifier.fileURL, itemIdentifier.title, itemIdentifier.publisher)
        }
        
        let grapeGameCellRegistration = UICollectionView.CellRegistration<GameCell, GrapeGame> { cell, indexPath, itemIdentifier in
            if !itemIdentifier.isGBA, let cgImage = self.cgImage(from: Grape.shared.icon(from: itemIdentifier.fileURL), width: 32, height: 32) {
                cell.imageView.image = .init(cgImage: cgImage)
            } else {
                cell.missingImageView.image = .init(systemName: "slash.circle")
            }
            cell.set(itemIdentifier.fileURL, itemIdentifier.title, itemIdentifier.size)
        }
        
        let lycheeGameCellRegistration = UICollectionView.CellRegistration<GameCell, LycheeGame> { cell, indexPath, itemIdentifier in
            cell.missingImageView.image = .init(systemName: "slash.circle")
            cell.set(itemIdentifier.fileURL, itemIdentifier.title, itemIdentifier.size)
        }
        
        let supplementaryViewRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.extraProminentInsetGroupedHeader()
            
            guard let sectionIdentifier = self.dataSource.sectionIdentifier(for: indexPath.section) as? Core else {
                return
            }
            
            contentConfiguration.text = sectionIdentifier.details.name.rawValue
            contentConfiguration.textProperties.color = .label
            contentConfiguration.secondaryText = sectionIdentifier.console.rawValue
            contentConfiguration.secondaryTextProperties.color = .secondaryLabel
            supplementaryView.contentConfiguration = contentConfiguration
            
            func coreSettingsButton(console: Core.Console) -> UIButton {
                var coreSettingsButtonConfiguration = UIButton.Configuration.borderless()
                coreSettingsButtonConfiguration.buttonSize = .medium
                coreSettingsButtonConfiguration.image = .init(systemName: "gearshape.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: .tintColor))
                
                return UIButton(configuration: coreSettingsButtonConfiguration, primaryAction: .init(handler: { _ in
                    let iniEditController = UINavigationController(rootViewController: INIEditController(console: console, url: sectionIdentifier.details.root.appendingPathComponent("config").appendingPathComponent("config.ini")))
                    iniEditController.modalPresentationStyle = .fullScreen
                    self.present(iniEditController, animated: true)
                }))
            }
            
            func missingFilesButton() -> UIButton {
                var configuration = UIButton.Configuration.borderless()
                configuration.buttonSize = .large
                let hierarchalColor: UIColor = if sectionIdentifier.missingFiles.contains(where: { $0.fileDetails.importance == .required }) { .systemRed } else { .systemOrange }
                configuration.image = .init(systemName: "exclamationmark.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: hierarchalColor))
                
                return UIButton(configuration: configuration, primaryAction: .init(handler: { _ in
                    
                    
                    let missingFilesController = UINavigationController(rootViewController: MissingFilesController(core: sectionIdentifier,
                                                                                                                   collectionViewLayout: Layouts.shared.missingFiles()))
                    missingFilesController.modalPresentationStyle = .fullScreen
                    self.present(missingFilesController, animated: true)
                }))
            }
            
            /*
            func coreSettingsButton(console: Core.Console) -> BlurredImageButton {
                let button = BlurredImageButton(with: {})
                button.set("gearshape.fill", .secondaryLabel)
                return button
            }
            
            func missingFilesButton() -> BlurredImageButton {
                let button = BlurredImageButton(with: {})
                button.set("exclamationmark.circle.fill", .secondaryLabel)
                return button
            }*/
            
            let coreSettingsView = UICellAccessory.customView(configuration: .init(customView: coreSettingsButton(console: sectionIdentifier.console), placement: .trailing()))
            let missingFilesView = UICellAccessory.customView(configuration: .init(customView: missingFilesButton(), placement: .trailing()))
            
            switch sectionIdentifier.console {
            case .n3ds, .nds:
                supplementaryView.accessories = [coreSettingsView]
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            case .psx:
                supplementaryView.accessories = []
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            default:
                supplementaryView.accessories = []
            }
        }
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let cytrusGame as CytrusGame:
                collectionView.dequeueConfiguredReusableCell(using: cytrusGameCellRegistration, for: indexPath, item: cytrusGame)
            case let grapeGame as GrapeGame:
                collectionView.dequeueConfiguredReusableCell(using: grapeGameCellRegistration, for: indexPath, item: grapeGame)
            case let lycheeGame as LycheeGame:
                collectionView.dequeueConfiguredReusableCell(using: lycheeGameCellRegistration, for: indexPath, item: lycheeGame)
            default:
                nil
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryViewRegistration, for: indexPath)
        }
        
        Task {
            try await updateDataSource()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let object = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch object {
        case let cytrusGame as CytrusGame:
            let cytrusEmulationController = CytrusEmulationController(console: .n3ds, game: cytrusGame)
            cytrusEmulationController.modalPresentationStyle = .fullScreen
            present(cytrusEmulationController, animated: true)
        case let grapeGame as GrapeGame:
            let grapeEmulationController = GrapeEmulationController(console: grapeGame.core.console, game: grapeGame)
            grapeEmulationController.modalPresentationStyle = .fullScreen
            present(grapeEmulationController, animated: true)
        // case let lycheeGame as LycheeGame:
        //     let lycheeEmulationController = LycheeEmulationController(console: lycheeGame.core.console, game: lycheeGame)
        //     lycheeEmulationController.modalPresentationStyle = .fullScreen
        //     present(lycheeEmulationController, animated: true)
        default:
            break
        }
    }
    
    @objc fileprivate func updateDataSource(_ isRefresh: Bool = false) async throws {
        if isRefresh {
            cores = []
            cores = try LibraryManager.shared.library()
            
            snapshot.deleteAllItems()
            snapshot.deleteSections(cores.sorted())
            
            await dataSource.apply(snapshot)
        }
        
        snapshot = .init()
        snapshot.appendSections(cores.sorted())
        cores.forEach { core in
            if !core.missingFiles.contains(where: { $0.fileDetails.importance == .required }), !core.games.isEmpty {
                switch core.games {
                case let cytrusGames as [CytrusGame]:
                    snapshot.appendItems(cytrusGames.sorted(), toSection: core)
                case let grapeGames as [GrapeGame]:
                    snapshot.appendItems(grapeGames.sorted(), toSection: core)
                case let lycheeGames as [LycheeGame]:
                    snapshot.appendItems(lycheeGames.sorted(), toSection: core)
                default:
                    break
                }
            }
        }
        
        await dataSource.apply(snapshot)
    }
    
    fileprivate func cgImage(from screenFramebuffer: UnsafeMutablePointer<UInt32>, width: Int, height: Int) -> CGImage? {
        var imageRef: CGImage? = nil
        
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue).union(.byteOrderDefault)
        guard let providerRef = CGDataProvider(dataInfo: nil, data: screenFramebuffer, size: totalBytes,
                                               releaseData: {_,_,_  in}) else {
            return nil
        }
        
        imageRef = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel,
                           bytesPerRow: bytesPerRow, space: colorSpaceRef, bitmapInfo: bitmapInfo, provider: providerRef,
                           decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        return imageRef
    }
}
