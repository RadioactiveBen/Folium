//
//  LycheeEmulationController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 18/4/2024.
//

/*
import Foundation
import GameController
import Lychee
import UIKit

class LycheeEmulationController : EmulationScreensController {
    fileprivate var lychee = Lychee.shared
    fileprivate var lycheeGame: LycheeGame!
    
    fileprivate var displayLink: CADisplayLink!
    fileprivate var thread1, thread2: Thread!
    fileprivate var isRunning: Bool = false
    
    fileprivate var toggleControlsButton: BlurredImageButton!
    
    override init(console: Core.Console, game: AnyHashable? = nil) {
        super.init(console: console, game: game)
        guard let game = game as? LycheeGame else {
            return
        }
        
        lycheeGame = game
        lychee.insert(game: game.fileURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 60, maximum: 60)
        
        toggleControlsButton = .init(with: {
            if self.virtualControllerView.alpha == 0 {
                UIView.animate(withDuration: 0.2) {
                    if UIApplication.shared.statusBarOrientation == .portrait {
                        self.toggleControlsButton.alpha = 0
                    }
                    self.virtualControllerView.alpha = 1
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.virtualControllerView.alpha = 0
                }
            }
        })
        toggleControlsButton.alpha = 0
        toggleControlsButton.set("eye.fill", .secondaryLabel)
        toggleControlsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleControlsButton)
        view.addConstraints([
            toggleControlsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toggleControlsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            
            //thread1.start()
            //thread2.start()
            
            displayLink.add(to: .main, forMode: .common)
            // while true {
            //     step()
            // }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.toggleControlsButton.alpha = self.virtualControllerView.alpha == 0 ? 1 : (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight) ? 1 : 0
        }
    }
    
    @objc fileprivate func step() {
        lychee.step()
        let screenFramebuffer = lychee.screenFramebuffer()
        guard let primaryScreen = primaryScreen as? UIImageView, let primaryBlurredScreen = primaryBlurredScreen as? UIImageView,
              let topCGImage = cgImage(from: screenFramebuffer, width: 1024, height: 512) else {
            return
        }
        
        primaryScreen.image = .init(cgImage: topCGImage)
        UIView.transition(with: primaryBlurredScreen, duration: 0.66, options: .transitionCrossDissolve) {
            primaryBlurredScreen.image = .init(cgImage: topCGImage)
        }
    }
    
    // MARK: Physical Controller Delegates
    override func controllerDidConnect(_ notification: Notification) {
        super.controllerDidConnect(notification)
        guard let controller = notification.object as? GCController, let extendedGamepad = controller.extendedGamepad else {
            return
        }
        
        extendedGamepad.dpad.up.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadUp) : self.touchUpInside(.dpadUp)
        }
        
        extendedGamepad.dpad.down.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadDown) : self.touchUpInside(.dpadDown)
        }
        
        extendedGamepad.dpad.left.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadLeft) : self.touchUpInside(.dpadLeft)
        }
        
        extendedGamepad.dpad.right.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadRight) : self.touchUpInside(.dpadRight)
        }
        
        extendedGamepad.buttonOptions?.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.minus) : self.touchUpInside(.minus)
        }
        
        extendedGamepad.buttonMenu.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.plus) : self.touchUpInside(.plus)
        }
        
        extendedGamepad.buttonA.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.a) : self.touchUpInside(.a)
        }
        
        extendedGamepad.buttonB.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.b) : self.touchUpInside(.b)
        }
        
        extendedGamepad.buttonX.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.x) : self.touchUpInside(.x)
        }
        
        extendedGamepad.buttonY.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.y) : self.touchUpInside(.y)
        }
        
        extendedGamepad.leftShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.l) : self.touchUpInside(.l)
        }
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }
    }
    
    // MARK: Virtual Controller Delegates
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
        switch buttonType {
        case .dpadUp:
            lychee.virtualControllerButtonDown(6)
        case .dpadDown:
            lychee.virtualControllerButtonDown(7)
        case .dpadLeft:
            lychee.virtualControllerButtonDown(5)
        case .dpadRight:
            lychee.virtualControllerButtonDown(4)
        case .minus:
            lychee.virtualControllerButtonDown(2)
        case .plus:
            lychee.virtualControllerButtonDown(3)
        case .a:
            lychee.virtualControllerButtonDown(0)
        case .b:
            lychee.virtualControllerButtonDown(1)
        case .x:
            lychee.virtualControllerButtonDown(10)
        case .y:
            lychee.virtualControllerButtonDown(11)
        case .l:
            lychee.virtualControllerButtonDown(9)
        case .r:
            lychee.virtualControllerButtonDown(8)
        default:
            break
        }
    }
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
        switch buttonType {
        case .dpadUp:
            lychee.virtualControllerButtonUp(6)
        case .dpadDown:
            lychee.virtualControllerButtonUp(7)
        case .dpadLeft:
            lychee.virtualControllerButtonUp(5)
        case .dpadRight:
            lychee.virtualControllerButtonUp(4)
        case .minus:
            lychee.virtualControllerButtonUp(2)
        case .plus:
            lychee.virtualControllerButtonUp(3)
        case .a:
            lychee.virtualControllerButtonUp(0)
        case .b:
            lychee.virtualControllerButtonUp(1)
        case .x:
            lychee.virtualControllerButtonUp(10)
        case .y:
            lychee.virtualControllerButtonUp(11)
        case .l:
            lychee.virtualControllerButtonUp(9)
        case .r:
            lychee.virtualControllerButtonUp(8)
        default:
            break
        }
    }
}
*/
