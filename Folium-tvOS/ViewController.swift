//
//  ViewController.swift
//  Folium
//
//  Created by Jarrod Norwell on 2/4/2024.
//

import Kiwi
import MultipeerConnectivity
import UIKit

struct Core : Comparable, Hashable {
    enum Name : String, Hashable {
        case cytrus = "Cytrus", grape = "Grape", kiwi = "Kiwi", sudachi = "Sudachi"
    }
    
    enum Console : String, Codable, Hashable {
        case n3ds = "Nintendo 3DS", nds = "Nintendo DS", nes = "Nintendo Entertainment System", nSwitch = "Nintendo Switch"
    }
    
    let console: Console
    let name: Name
    
    static func < (lhs: Core, rhs: Core) -> Bool {
        lhs.name.rawValue < rhs.name.rawValue
    }
}

struct Package : Codable {
    let console: Core.Console
    let data: Data
}

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    fileprivate var advertiser: MCNearbyServiceAdvertiser!
    fileprivate var peer: MCPeerID!
    fileprivate var session: MCSession!
    
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate let kiwi = Kiwi.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMultipeerConnectivity()
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 60, preferred: 60)
        
        imageView.clipsToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = 12
    }
    
    fileprivate func configureMultipeerConnectivity() {
        peer = .init(displayName: UIDevice.current.name)
        
        advertiser = .init(peer: peer, discoveryInfo: nil, serviceType: "folium")
        advertiser.delegate = self
        
        session = .init(peer: peer, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        advertiser.startAdvertisingPeer()
    }
    
    @objc fileprivate func step() {
        kiwi.step()
        
        guard let cgImage = cgImage(from: kiwi.screenFramebuffer(), width: 256 * 6, height: 240 * 6) else {
            return
        }
        
        Task {
            imageView.image = .init(cgImage: cgImage)
        }
    }
    
    fileprivate func cgImage(from screenFramebuffer: UnsafeMutablePointer<UInt32>, width: Int, height: Int) -> CGImage? {
        var imageRef: CGImage?
        
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

extension ViewController : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension ViewController : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected, .connecting:
            break
        case .connected:
            advertiser.stopAdvertisingPeer()
        default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                return
            }
            
            let package = try JSONDecoder().decode(Package.self, from: data)
            try package.data.write(to: cachesDirectory.appendingPathComponent("temp.rom", conformingTo: .fileURL))
            kiwi.insert(game: cachesDirectory.appendingPathComponent("temp.rom", conformingTo: .fileURL))
            
            // session.disconnect()
            
            displayLink.add(to: .main, forMode: .common)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
}
