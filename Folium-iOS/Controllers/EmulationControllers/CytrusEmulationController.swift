//
//  CytrusEmulationController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 18/4/2024.
//

import Cytrus
import Foundation
import GameController
import MetalKit
import UIKit

class CytrusEmulationController : EmulationScreensController {
    fileprivate let cytrus = Cytrus.shared
    fileprivate var cytrusGame: CytrusGame!
    
    fileprivate var thread: Thread!
    fileprivate var isRunning: Bool = false
    
    override init(console: Core.Console, game: AnyHashable? = nil) {
        super.init(console: console, game: game)
        guard let game = game as? CytrusGame else {
            return
        }
        
        cytrusGame = game
        
        thread = .init(block: step)
        thread.name = "Cytrus"
        thread.qualityOfService = .userInteractive
        thread.threadPriority = 0.9
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        NotificationCenter.default.addObserver(forName: .init("sceneDidChange"), object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let state = userInfo["state"] as? Int else {
                return
            }
            
            self.cytrus.pausePlay(state == 1 ? true : false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            guard let cytrusGame, let primaryScreen = primaryScreen as? MTKView/*, let secondaryScreen = secondaryScreen as? MTKView*/ else {
                return
            }
            
            cytrus.configure(primaryLayer: primaryScreen.layer as! CAMetalLayer, with: primaryScreen.frame.size/*,
                             secondaryLayer: secondaryScreen.layer as! CAMetalLayer, secondarySize: secondaryScreen.frame.size*/)
            cytrus.insert(game: cytrusGame.fileURL)
            
            thread.start()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.cytrus.orientationChanged(orientation: UIApplication.shared.statusBarOrientation, with: self.primaryScreen.frame.size)
            // self.cytrus.orientationChanged(orientation: UIApplication.shared.statusBarOrientation, with: self.secondaryScreen.frame.size)
        }
    }
    
    @objc fileprivate func step() {
        while true {
            cytrus.step()
        }
    }
    
    // MARK: Touch Delegates
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        func position(in view: UIView, with location: CGPoint) -> (x: Float, y: Float) {
            let radius = view.frame.width / 2
            return (Float((location.x - radius) / radius), Float(-(location.y - radius) / radius))
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: position(in: virtualControllerView.dpadView,
                                                           with: touch.location(in: virtualControllerView.dpadView)).x,
                                   y: position(in: virtualControllerView.dpadView, with: touch.location(in: virtualControllerView.dpadView)).y)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: position(in: virtualControllerView.xybaView,
                                                        with: touch.location(in: virtualControllerView.xybaView)).x,
                                   y: position(in: virtualControllerView.xybaView, with: touch.location(in: virtualControllerView.xybaView)).y)
        case primaryScreen:
        // case secondaryScreen:
            cytrus.touchBegan(at: touch.location(in: primaryScreen))
            // cytrus.touchBegan(at: touch.location(in: secondaryScreen))
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: 0, y: 0)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: 0, y: 0)
        case primaryScreen:
        // case secondaryScreen:
            cytrus.touchEnded()
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        func position(in view: UIView, with location: CGPoint) -> (x: Float, y: Float) {
            let radius = view.frame.width / 2
            return (Float((location.x - radius) / radius), Float(-(location.y - radius) / radius))
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: position(in: virtualControllerView.dpadView,
                                                           with: touch.location(in: virtualControllerView.dpadView)).x,
                                   y: position(in: virtualControllerView.dpadView, with: touch.location(in: virtualControllerView.dpadView)).y)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: position(in: virtualControllerView.xybaView,
                                                        with: touch.location(in: virtualControllerView.xybaView)).x,
                                   y: position(in: virtualControllerView.xybaView, with: touch.location(in: virtualControllerView.xybaView)).y)
        case primaryScreen:
        // case secondaryScreen:
            cytrus.touchMoved(at: touch.location(in: primaryScreen))
            // cytrus.touchMoved(at: touch.location(in: secondaryScreen))
        default:
            break
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
        
        extendedGamepad.leftTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.zl) : self.touchUpInside(.zl)
        }
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }
        
        extendedGamepad.rightTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.zr) : self.touchUpInside(.zr)
        }
        
        extendedGamepad.leftThumbstick.valueChangedHandler = { dpad, x, y in
            self.cytrus.thumbstickMoved(.circlePad, x: x, y: y)
        }
        
        extendedGamepad.rightThumbstick.valueChangedHandler = { dpad, x, y in
            self.cytrus.thumbstickMoved(.cStick, x: x, y: y)
        }
    }
    
    // MARK: Virtual Controller Delegates
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
        switch buttonType {
        case .dpadUp:
            cytrus.virtualControllerButtonDown(.directionalPadUp)
        case .dpadDown:
            cytrus.virtualControllerButtonDown(.directionalPadDown)
        case .dpadLeft:
            cytrus.virtualControllerButtonDown(.directionalPadLeft)
        case .dpadRight:
            cytrus.virtualControllerButtonDown(.directionalPadRight)
        case .minus:
            cytrus.virtualControllerButtonDown(.select)
        case .plus:
            cytrus.virtualControllerButtonDown(.start)
        case .a:
            cytrus.virtualControllerButtonDown(.A)
        case .b:
            cytrus.virtualControllerButtonDown(.B)
        case .x:
            cytrus.virtualControllerButtonDown(.X)
        case .y:
            cytrus.virtualControllerButtonDown(.Y)
        case .l:
            cytrus.virtualControllerButtonDown(.triggerL)
        case .zl:
            cytrus.virtualControllerButtonDown(.triggerZL)
        case .r:
            cytrus.virtualControllerButtonDown(.triggerR)
        case .zr:
            cytrus.virtualControllerButtonDown(.triggerZR)
        }
    }
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
        switch buttonType {
        case .dpadUp:
            cytrus.virtualControllerButtonUp(.directionalPadUp)
        case .dpadDown:
            cytrus.virtualControllerButtonUp(.directionalPadDown)
        case .dpadLeft:
            cytrus.virtualControllerButtonUp(.directionalPadLeft)
        case .dpadRight:
            cytrus.virtualControllerButtonUp(.directionalPadRight)
        case .minus:
            cytrus.virtualControllerButtonUp(.select)
        case .plus:
            cytrus.virtualControllerButtonUp(.start)
        case .a:
            cytrus.virtualControllerButtonUp(.A)
        case .b:
            cytrus.virtualControllerButtonUp(.B)
        case .x:
            cytrus.virtualControllerButtonUp(.X)
        case .y:
            cytrus.virtualControllerButtonUp(.Y)
        case .l:
            cytrus.virtualControllerButtonUp(.triggerL)
        case .zl:
            cytrus.virtualControllerButtonUp(.triggerZL)
        case .r:
            cytrus.virtualControllerButtonUp(.triggerR)
        case .zr:
            cytrus.virtualControllerButtonUp(.triggerZR)
        }
    }
}
