//
//  MultipeerController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 5/4/2024.
//

import Foundation
import MultipeerConnectivity
import UIKit

struct Package : Codable {
    let console: Core.Console
    let data: Data
}

class MultipeerController : UICollectionViewController {
    fileprivate var dataSource: UICollectionViewDiffableDataSource<String, MCPeerID>! = nil
    fileprivate var snapshot: NSDiffableDataSourceSnapshot<String, MCPeerID>! = nil
    
    fileprivate var browser: MCNearbyServiceBrowser!
    fileprivate var peer: MCPeerID!
    fileprivate var session: MCSession!
    
    fileprivate var console: Core.Console
    fileprivate var game: URL
    init(collectionViewLayout: UICollectionViewLayout, console: Core.Console, game: URL) {
        self.console = console
        self.game = game
        super.init(collectionViewLayout: collectionViewLayout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMultipeerConnectivity()
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MCPeerID> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = itemIdentifier.displayName
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        snapshot = .init()
        snapshot.appendSections(["Devices"])
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let peer = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        browser.invitePeer(peer, to: session, withContext: nil, timeout: .zero)
    }
    
    fileprivate func configureMultipeerConnectivity() {
        peer = .init(displayName: UIDevice.current.name)
        
        browser = .init(peer: peer, serviceType: "folium")
        browser.delegate = self
        
        session = .init(peer: peer, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        browser.startBrowsingForPeers()
    }
}

extension MultipeerController : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        snapshot.appendItems([peerID], toSection: "Devices")
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        snapshot.deleteItems([peerID])
        Task {
            await dataSource.apply(snapshot)
        }
    }
}

extension MultipeerController : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let peer = session.connectedPeers.first else {
            return
        }
        
        switch state {
        case .notConnected, .connecting:
            break
        case .connected:
            browser.stopBrowsingForPeers()
            do {
                let package = Package(console: console, data: try .init(contentsOf: game))
                
                try session.send(try JSONEncoder().encode(package), toPeers: [peer], with: .reliable)
                // session.disconnect()
            } catch {
                print(error.localizedDescription)
            }
        default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
}
