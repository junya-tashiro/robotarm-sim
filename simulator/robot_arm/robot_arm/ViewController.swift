//
//  ViewController.swift
//  robot_arm
//
//  Created by 田代純也 on 2024/02/10.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    let sceneView = SCNView()
    let originNode = SCNNode()
    let controllerView = UIView()
    let consoleView = UIScrollView()
    let console = UILabel()
    let consoleBar = UIView()
    var consoleText: String = ""
    var consoleHeight: Int = 300
    var controllerWidth: Int = 350
    
    var touchConsoleBar: Bool = false
    
    var arm: Arm!
    
    let slider1 = UISlider()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sendFinishMsg(_:)), name: UIApplication.willTerminateNotification, object: nil)
        
        self.view.frame = CGRect(x: 0, y: 0, width: 1000, height: 600)
        
        self.controllerView.frame = CGRect(x: Int(self.view.frame.width) - self.controllerWidth, y: 0, width: self.controllerWidth, height: Int(self.view.frame.height))
        self.controllerView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        self.view.addSubview(self.controllerView)
        
        self.consoleBar.frame = CGRect(x: 0, y: Int(self.view.frame.height) - self.consoleHeight - 40, width: Int(self.view.frame.width) - self.controllerWidth, height: 40)
        self.consoleBar.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        self.view.addSubview(self.consoleBar)
        
        self.consoleView.frame = CGRect(x: 0, y: Int(self.view.frame.height) - self.consoleHeight, width: Int(self.view.frame.width) - self.controllerWidth, height: self.consoleHeight)
        self.consoleView.contentSize = CGSize(width: Int(self.view.frame.width) - self.controllerWidth, height: self.consoleHeight)
        self.consoleView.backgroundColor = .black
        self.view.addSubview(consoleView)
        
        self.console.frame = CGRect(x: 15, y: 0, width: Int(self.consoleView.frame.width) - 30, height: self.consoleHeight)
        self.console.numberOfLines = 0
        self.console.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        self.console.textColor = UIColor.white
        self.console.sizeToFit()
        self.consoleView.addSubview(self.console)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: {_ in
            self.updateFunc()
        })
        
        //シーンの設定
        self.setScene()
        
        //アームのインスタンス化
        self.arm = Arm(originNode: originNode, controllerView: controllerView, angles: [45, 30, 60, 45, 90, 70], addToConsole: addToConsole(txt:))
    }

    func setScene() {
        sceneView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 350, height: self.view.frame.height - CGFloat(self.consoleHeight) - 40)
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor.lightGray
        self.view.addSubview(sceneView)
        
        originNode.scale = SCNVector3(10, 10, 10)
        self.sceneView.scene?.rootNode.addChildNode(originNode)

        //カメラ
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        sceneView.scene!.rootNode.addChildNode(cameraNode)
        sceneView.allowsCameraControl = true
        
        //光源
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1000
        light.color = UIColor.white.cgColor
        light.castsShadow = true
        let light2 = SCNLight()
        light2.type = .omni
        light2.intensity = 700
        light2.color = UIColor.white.cgColor
        light2.castsShadow = false
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 30, y: 30, z: 10)
        sceneView.scene!.rootNode.addChildNode(lightNode)
        let lightNode2 = SCNNode()
        lightNode2.light = light2
        lightNode2.position = SCNVector3(x: -10, y: 30, z: -30)
        sceneView.scene!.rootNode.addChildNode(lightNode2)
        
        //地面
        let planeNode = SCNNode()
        planeNode.geometry = SCNBox(width: 10, height: 0.01, length: 10, chamferRadius: 0)
        planeNode.position.y = -0.005
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        sceneView.scene!.rootNode.addChildNode(planeNode)
        
        for i in -4 ..< 5 {
            let x1 = SCNNode()
            x1.geometry = SCNBox(width: 10, height: 0.01, length: 0.005, chamferRadius: 0)
            x1.position.z = Float(i)
            x1.position.y = -0.00499
            if i == 0 {
                x1.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
            else {
                x1.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
            }
            sceneView.scene!.rootNode.addChildNode(x1)
            
            let z1 = SCNNode()
            z1.geometry = SCNBox(width: 0.005, height: 0.01, length: 10, chamferRadius: 0)
            z1.position.x = Float(i)
            z1.position.y = -0.00499
            if i == 0 {
                z1.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            }
            else {
                z1.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
            }
            sceneView.scene!.rootNode.addChildNode(z1)
        }
    }
    
    func addToConsole(txt: String) {
        consoleText.append("\n>> " + txt)
        console.text = consoleText + "\n"
        console.sizeToFit()
        console.frame = CGRect(x: 15, y: 0, width: Int(self.consoleView.frame.width) - 30, height: Int(console.frame.height))
        consoleView.contentSize = CGSize(width: self.consoleView.frame.width, height: console.frame.height)
        
        if consoleView.contentSize.height > consoleView.frame.height {
            consoleView.contentOffset = CGPoint(x: 0, y: consoleView.contentSize.height - consoleView.frame.height)
        }
    }
    
    var n: Int = 0
    
    func updateFunc() {
        sceneView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - CGFloat(self.controllerWidth), height: self.view.frame.height - CGFloat(self.consoleHeight) - 40)
        controllerView.frame = CGRect(x: Int(self.view.frame.width) - self.controllerWidth, y: 0, width: self.controllerWidth, height: Int(self.view.frame.height))
        consoleView.frame = CGRect(x: 0, y: Int(self.view.frame.height) - self.consoleHeight, width: Int(self.view.frame.width) - self.controllerWidth, height: self.consoleHeight)
        console.frame = CGRect(x: 15, y: 0, width: Int(self.consoleView.frame.width) - 30, height: Int(console.frame.height))
        consoleView.contentSize = CGSize(width: self.consoleView.frame.width, height: console.frame.height)
        consoleBar.frame = CGRect(x: 0, y: Int(self.view.frame.height) - self.consoleHeight - 40, width: Int(self.view.frame.width) - self.controllerWidth, height: 40)
        
        arm.updateShow()
    }
    
    @objc func sendFinishMsg(_ sender: Any) {
        arm.sendFinishMsg()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPos = touch.location(in: self.view)
        
        let y = self.view.frame.height - CGFloat(self.consoleHeight) - touchPos.y
        if abs(y - 20) < 20 {
            self.touchConsoleBar = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPos = touch.location(in: self.view)
        
        if self.touchConsoleBar {
            var d = Int(self.view.frame.height - touchPos.y - 20)
            if d <= 0 { d = 0 }
            else if d >= Int(self.view.frame.height - 40) { d = Int(self.view.frame.height - 40) }
            self.consoleHeight = d
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchConsoleBar = false
    }
}
