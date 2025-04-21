//
//  Arm.swift
//  robot_arm
//
//  Created by 田代純也 on 2024/02/09.
//

import Foundation
import SwiftUI
import SceneKit
import Network

class Arm {
    let myBlue = UIColor(red: 0.2, green: 0.1, blue: 0.7, alpha: 1.0)
    
    var screen_y: Int = 70
    
    var timer = Timer()
    
    var angles: [Float] = [0, 0, 0, 0, 0, 0]
    var angles_ref: [Float] = [0, 0, 0, 0, 0, 0]
    var originNode: SCNNode
    var controllerView: UIView
    var sliders: [UISlider] = []
    var angleLabels: [UILabel] = []
    
    var labelsForIK: [UILabel] = []
    var pmButtons: [UIButton] = []
    
    var addToConsole: (String) -> ()

    let host: NWEndpoint.Host = "127.0.0.1"
    let port: NWEndpoint.Port = 12345
    let connection: NWConnection
    
    var bodyNodes: [SCNNode] = []
    var bodyNodesRef: [SCNNode] = []
    var endefectorNodes: [SCNNode] = []
    let graspNode = SCNNode()
    let graspNodeRef = SCNNode()
    
    var counter: Int = 0
    
    //各種パラメータ
    let x_origin: Float
    let y_origin: Float
    let delta_y: Float
    let h_2_to_1: Float
    let h_3_to_2: Float
    let z_origin: Float
    let l_1: Float
    let l_2: Float
    let k1: Float
    let k2: Float
    
    init(originNode: SCNNode, controllerView: UIView, angles: [Float] = [0, 0, 0, 0, 0, 0], addToConsole: @escaping ((String) -> ())) {
        self.originNode = originNode
        self.controllerView = controllerView
        self.angles = angles
        self.angles_ref = angles
        self.addToConsole = addToConsole
        
        self.connection = NWConnection(host: host, port: port, using: .udp)
        connection.start(queue: .global())
        
        x_origin = -0.0045
        y_origin = -0.01
        delta_y = 0.01
        h_2_to_1 = 0.074
        h_3_to_2 = 0.0405
        z_origin = h_2_to_1 + h_3_to_2
        l_1 = 0.105
        l_2 = 0.097
        k1 = 0.161
        k2 = 0.025
        
        self.setBodyNodes()
        self.setEndefectorNodes()
        self.setBodyNodesRef()
        self.updateShow()
        self.setGraspNode()
        self.setButtonsForFK()
        self.setButtonsForIK()
    }
    
    func setBodyNodes() {
        let bodyScene_01 = SCNScene(named: "bodys/body_01.scn")
        let bodyNode_01 = (bodyScene_01?.rootNode.childNode(withName: "body_01", recursively: true))!
        originNode.addChildNode(bodyNode_01)
        bodyNodes.append(bodyNode_01)
        
        let bodyScene_02 = SCNScene(named: "bodys/body_02.scn")
        let bodyNode_02 = (bodyScene_02?.rootNode.childNode(withName: "body_02", recursively: true))!
        bodyNode_02.position = SCNVector3(-y_origin, h_2_to_1, -x_origin)
        bodyNode_01.addChildNode(bodyNode_02)
        bodyNodes.append(bodyNode_02)
        
        let bodyScene_03 = SCNScene(named: "bodys/body_03.scn")
        let bodyNode_03 = (bodyScene_03?.rootNode.childNode(withName: "body_03", recursively: true))!
        bodyNode_03.position = SCNVector3(0.0, h_3_to_2, 0.0)
        bodyNode_02.addChildNode(bodyNode_03)
        bodyNodes.append(bodyNode_03)
        
        let bodyScene_04 = SCNScene(named: "bodys/body_04.scn")
        let bodyNode_04 = (bodyScene_04?.rootNode.childNode(withName: "body_04", recursively: true))!
        bodyNode_04.position = SCNVector3(l_1, 0.0, 0.0)
        bodyNode_03.addChildNode(bodyNode_04)
        bodyNodes.append(bodyNode_04)
        
        let bodyScene_05 = SCNScene(named: "bodys/body_05.scn")
        let bodyNode_05 = (bodyScene_05?.rootNode.childNode(withName: "body_05", recursively: true))!
        bodyNode_05.position = SCNVector3(l_2, 0.0, -0.006)
        bodyNode_04.addChildNode(bodyNode_05)
        bodyNodes.append(bodyNode_05)
    }
    
    func setEndefectorNodes() {
        let endefectorScene = SCNScene(named: "bodys/endefector.scn")
        
        let endefectorNode_01 = (endefectorScene?.rootNode.childNode(withName: "endefector_01", recursively: true))!
        endefectorNode_01.position = SCNVector3(x: 0.081, y: 0.025, z: 0.016)
        bodyNodes[4].addChildNode(endefectorNode_01)
        endefectorNodes.append(endefectorNode_01)
        
        let endefectorNode_02 = (endefectorScene?.rootNode.childNode(withName: "endefector_02", recursively: true))!
        endefectorNode_02.position = SCNVector3(x: 0.0, y: 0.006, z: 0.015)
        endefectorNode_01.addChildNode(endefectorNode_02)
        endefectorNodes.append(endefectorNode_02)
        
        let endefectorNode_03 = (endefectorScene?.rootNode.childNode(withName: "endefector_03", recursively: true))!
        endefectorNode_03.position = SCNVector3(x: 0.0, y: 0.006, z: -0.015)
        endefectorNode_01.addChildNode(endefectorNode_03)
        endefectorNodes.append(endefectorNode_03)
        
        let endefectorNode_04 = (endefectorScene?.rootNode.childNode(withName: "endefector_04", recursively: true))!
        endefectorNode_04.position = SCNVector3(x: 0.02, y: 0.006, z: 0.005)
        endefectorNode_01.addChildNode(endefectorNode_04)
        endefectorNodes.append(endefectorNode_04)
        
        let endefectorNode_05 = (endefectorScene?.rootNode.childNode(withName: "endefector_05", recursively: true))!
        endefectorNode_05.position = SCNVector3(x: 0.02, y: 0.006, z: -0.005)
        endefectorNode_01.addChildNode(endefectorNode_05)
        endefectorNodes.append(endefectorNode_05)
        
        let endefectorNode_06 = (endefectorScene?.rootNode.childNode(withName: "endefector_07", recursively: true))!
        endefectorNode_06.position = SCNVector3(x: 0.03, y: -0.0045, z: 0.0)
        endefectorNode_02.addChildNode(endefectorNode_06)
        endefectorNodes.append(endefectorNode_06)
        
        let endefectorNode_07 = (endefectorScene?.rootNode.childNode(withName: "endefector_06", recursively: true))!
        endefectorNode_07.position = SCNVector3(x: 0.03, y: -0.0045, z: 0.0)
        endefectorNode_03.addChildNode(endefectorNode_07)
        endefectorNodes.append(endefectorNode_07)
        
        let endefectorNode_end = SCNNode()
        endefectorNode_end.position = SCNVector3(x: 0.08, y: 0.0015, z: 0.0)
        endefectorNode_01.addChildNode(endefectorNode_end)
        endefectorNodes.append(endefectorNode_end)
    }
    
    func setGraspNode() {
        let fk = self.forwardKinematics()
        graspNode.transform = fk.actual
        graspNodeRef.transform = fk.ref
        originNode.addChildNode(graspNode)
        originNode.addChildNode(graspNodeRef)
        
        let r: CGFloat = 0.0008
        let h: CGFloat = 0.05
        
        let axisNode_x = SCNNode(geometry: SCNCylinder(radius: r, height: h))
        axisNode_x.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        axisNode_x.position.x = Float(h / 2)
        axisNode_x.rotation = SCNVector4(x: 0, y: 0, z: 1, w: Float.pi/2)
        graspNode.addChildNode(axisNode_x)
        
        let axisNode_y = SCNNode(geometry: SCNCylinder(radius: r, height: h))
        axisNode_y.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        axisNode_y.position.y = Float(h / 2)
        graspNode.addChildNode(axisNode_y)
        
        let axisNode_z = SCNNode(geometry: SCNCylinder(radius: r, height: h))
        axisNode_z.geometry?.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
        axisNode_z.position.z = -Float(h / 2)
        axisNode_z.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float.pi/2)
        graspNode.addChildNode(axisNode_z)
    }
    
    func setBodyNodesRef() {
        for i in 0 ..< bodyNodes.count + 2 {
            let bodyNodeRef = SCNNode()
            if i == bodyNodes.count {
                bodyNodeRef.transform = endefectorNodes[0].transform
            }
            else if i == bodyNodes.count + 1 {
                bodyNodeRef.transform = endefectorNodes[endefectorNodes.count-1].transform
            }
            else {
                bodyNodeRef.transform = bodyNodes[i].transform
            }
            if i == 0 {
                originNode.addChildNode(bodyNodeRef)
            }
            else {
                bodyNodesRef[i-1].addChildNode(bodyNodeRef)
            }
            bodyNodesRef.append(bodyNodeRef)
        }
    }
    
    func setButtonsForFK() {
        let nameLabel = UILabel(frame: CGRectMake(0, 0, 200, 50))
        nameLabel.center = CGPoint(x: 175, y: self.screen_y)
        nameLabel.text = "Forward Kinematics"
        nameLabel.font = UIFont.systemFont(ofSize: 20)
        nameLabel.textAlignment = .center
        self.controllerView.addSubview(nameLabel)
        self.screen_y += 50
        for i in 0 ..< 6 {
            let slider = UISlider(frame: CGRectMake(0, 0, 200, 50))
            slider.center = CGPoint(x: 175, y: self.screen_y)
            slider.tintColor = myBlue
            slider.minimumValue = 0.0
            slider.maximumValue = 180.0
            slider.value = Float(self.angles[i])
            slider.addTarget(self, action: #selector(self.updateAngles(_:)), for: .valueChanged)
            self.controllerView.addSubview(slider)
            self.sliders.append(slider)
            
            let angleNameLabel = UILabel(frame: CGRectMake(0, 0, 50, 50))
            angleNameLabel.center = CGPoint(x: 50, y: self.screen_y)
            angleNameLabel.text = "θ" + String(i + 1)
            angleNameLabel.textAlignment = .center
            self.controllerView.addSubview(angleNameLabel)
            
            let angleLabel = UILabel(frame: CGRectMake(0, 0, 50, 30))
            angleLabel.center = CGPoint(x: 300, y: self.screen_y)
            angleLabel.text = String(Int(self.angles[i])) + "°"
            angleLabel.textAlignment = .center
            angleLabel.layer.cornerRadius = 5
            angleLabel.layer.borderWidth = 1
            angleLabel.layer.borderColor = UIColor.black.cgColor
            self.controllerView.addSubview(angleLabel)
            self.angleLabels.append(angleLabel)
            
            self.screen_y += 60
        }
        
        let sendAngleButton = UIButton(frame: CGRectMake(0, 0, 120, 40))
        sendAngleButton.center = CGPoint(x: 175 + 80, y: self.screen_y)
        sendAngleButton.backgroundColor = myBlue
        sendAngleButton.setTitle("send angles", for: .normal)
        sendAngleButton.layer.cornerRadius = 10
        sendAngleButton.addTarget(self, action: #selector(self.touchDown(_:)), for: .touchDown)
        sendAngleButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpInside)
        sendAngleButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpOutside)
        sendAngleButton.addTarget(self, action: #selector(self.sendAngleData(_:)), for: .touchUpInside)
        self.controllerView.addSubview(sendAngleButton)
        
        let graspButton = UIButton(frame: CGRectMake(0, 0, 120, 40))
        graspButton.center = CGPoint(x: 175 - 80, y: self.screen_y)
        graspButton.backgroundColor = UIColor.gray
        graspButton.setTitle("grasp", for: .normal)
        graspButton.layer.cornerRadius = 10
        graspButton.addTarget(self, action: #selector(self.touchDown(_:)), for: .touchDown)
        graspButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpInside)
        graspButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpOutside)
        graspButton.addTarget(self, action: #selector(self.graspBtnAction(_:)), for: .touchUpInside)
        self.controllerView.addSubview(graspButton)
        
        self.screen_y += 50
        
        let line = UILabel(frame: CGRectMake(0, 0, 300, 1))
        line.center = CGPoint(x: 175, y: self.screen_y)
        line.backgroundColor = .lightGray
        self.controllerView.addSubview(line)
        
        self.screen_y += 50
    }
    
    func setButtonsForIK() {
        let nameLabel = UILabel(frame: CGRectMake(0, 0, 200, 50))
        nameLabel.center = CGPoint(x: 175, y: self.screen_y)
        nameLabel.text = "Inverse Kinematics"
        nameLabel.font = UIFont.systemFont(ofSize: 20)
        nameLabel.textAlignment = .center
        self.controllerView.addSubview(nameLabel)
        
        self.screen_y += 60
        
        for i in 0 ..< 5 {
            let label = UILabel(frame: CGRectMake(0, 0, 60, 30))
            label.center = CGPoint(x: 190, y: self.screen_y)
            label.textAlignment = .right
            label.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            self.controllerView.addSubview(label)
            self.labelsForIK.append(label)
            
            let unitLabel = UILabel(frame: CGRectMake(0, 0, 30, 30))
            unitLabel.center = CGPoint(x: 240, y: self.screen_y)
            unitLabel.textAlignment = .left
            unitLabel.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            if i <= 2 { unitLabel.text = "m" }
            else      { unitLabel.text = "°" }
            self.controllerView.addSubview(unitLabel)
            
            let variableLabel = UILabel(frame: CGRectMake(0, 0, 40, 30))
            variableLabel.center = CGPoint(x: 135, y: self.screen_y)
            variableLabel.textAlignment = .left
            variableLabel.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            if i == 0      { variableLabel.text = " x =" }
            else if i == 1 { variableLabel.text = " y =" }
            else if i == 2 { variableLabel.text = " z =" }
            else if i == 3 { variableLabel.text = "φx =" }
            else if i == 4 { variableLabel.text = "φy =" }
            self.controllerView.addSubview(variableLabel)
            
            let frame = UILabel(frame: CGRectMake(0, 0, 135, 30))
            frame.center = CGPoint(x: 175, y: self.screen_y)
            frame.layer.cornerRadius = 5
            frame.layer.borderWidth = 1
            self.controllerView.addSubview(frame)
            
            for j in 0 ..< 4 {
                let pmButton = UIButton(frame: CGRectMake(0, 0, 25, 30))
                if j == 0      {
                    pmButton.center = CGPoint(x: 260, y: self.screen_y)
                    pmButton.setTitle(">", for: .normal)
                }
                else if j == 1 {
                    pmButton.center = CGPoint(x: 290, y: self.screen_y)
                    pmButton.setTitle("≫", for: .normal)
                }
                else if j == 2 {
                    pmButton.center = CGPoint(x: 90, y: self.screen_y)
                    pmButton.setTitle("<", for: .normal)
                }
                else if j == 3 {
                    pmButton.center = CGPoint(x: 60, y: self.screen_y)
                    pmButton.setTitle("≪", for: .normal)
                }
                pmButton.setTitleColor(self.controllerView.backgroundColor, for: .normal)
                pmButton.backgroundColor = .gray
                pmButton.layer.borderWidth = 0
                pmButton.layer.cornerRadius = 5
                pmButton.addTarget(self, action: #selector(self.touchDown(_:)), for: .touchDown)
                pmButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpInside)
                pmButton.addTarget(self, action: #selector(self.touchUp(_:)), for: .touchUpOutside)
                pmButton.addTarget(self, action: #selector(self.pmBtnAction(_:)), for: .touchUpInside)
                self.controllerView.addSubview(pmButton)
                pmButtons.append(pmButton)
            }
            
            self.screen_y += 60
        }
        
        self.setValuesForIKLabels()
    }
    
    func setValuesForIKLabels() {
        if labelsForIK.count != 0 {
            labelsForIK[0].text = String(format: "%.3f", -self.graspNodeRef.position.z)
            labelsForIK[1].text = String(format: "%.3f", -self.graspNodeRef.position.x)
            labelsForIK[2].text = String(format: "%.3f", self.graspNodeRef.position.y)
            labelsForIK[3].text = String(Int(self.angles_ref[4]) - 90)
            labelsForIK[4].text = String(Int(self.angles_ref[1] - self.angles_ref[2] - self.angles_ref[3]) + 90)
        }
    }
    
    @objc func pmBtnAction(_ sender: UIButton) {
        var type: Int = 0
        for i in 0 ..< 5 {
            if sender == pmButtons[4*i]        { type = 1 }
            else if sender == pmButtons[4*i+1] { type = 2 }
            else if sender == pmButtons[4*i+2] { type = 3 }
            else if sender == pmButtons[4*i+3] { type = 4 }
            
            if type != 0 {
                var x: Float = -self.graspNodeRef.position.z
                var y: Float = -self.graspNodeRef.position.x
                var z: Float = self.graspNodeRef.position.y
                var phi_x: Float = self.angles_ref[4] - 90
                var phi_y: Float = self.angles_ref[1] - self.angles_ref[2] - self.angles_ref[3] + 90
                
                var delta: Float = 1.0
                if type == 1      { delta = 0.01  }
                else if type == 2 { delta = 0.1   }
                else if type == 3 { delta = -0.01 }
                else if type == 4 { delta = -0.1  }
                
                if i == 0      { x += delta }
                else if i == 1 { y += delta }
                else if i == 2 { z += delta }
                else if i == 3 { phi_x += delta * 100 }
                else if i == 4 { phi_y += delta * 100 }
                
                let ik = self.inverseKinematics(x: x, y: y, z: z, phi_x: phi_x, phi_y: phi_y)
                if ik.canSolve {
                    for i in 0 ..< 5 { self.angles_ref[i] = ik.refAngles[i] }
                    var txt = "IK solved: ["
                    for i in 0 ..< 6 {
                        self.sliders[i].value = Float(Int(self.angles_ref[i]))
                        self.angleLabels[i].text = String(Int(self.angles_ref[i])) + "°"
                        txt.append(String(Int(self.angles_ref[i])) + ",")
                    }
                    txt.removeLast()
                    txt.append("]")
                    self.addToConsole(txt)
                }
                else {
                    self.addToConsole("error: can't solve IK")
                }
                return
            }
            
            type = 0
        }
    }
    
    @objc func updateAngles(_ sender: Any) {
        for i in 0 ..< 6 {
            self.angles_ref[i] = Float(Int(self.sliders[i].value))
            self.angleLabels[i].text = String(Int(self.angles_ref[i])) + "°"
        }
    }
    
    @objc func touchDown(_ sender: UIButton) { sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) }
    @objc func touchUp(_ sender: UIButton) { sender.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) }
    
    @objc func sendAngleData(_ sender: Any) {
        var msg = ""
        for angle in angles_ref {
            msg.append(String(Int(angle)) + ",")
        }
        msg.removeLast()
        connection.send(content: msg.data(using: .utf8), completion: .contentProcessed({sendError in}))
        self.addToConsole("send angles to Arduino: [" + msg + "]")
    }
    
    @objc func graspBtnAction(_ sender: UIButton) {
        if self.angles[5] > 71 {
            self.angles_ref[5] = 70
            self.sliders[5].value = 70
            self.angleLabels[5].text = "70°"
            sender.setTitle("grasp", for: .normal)
        }
        else {
            self.angles_ref[5] = 133
            self.sliders[5].value = 133
            self.angleLabels[5].text = "133°"
            sender.setTitle("release", for: .normal)
        }
        self.sendAngleData(sender)
    }
    
    func sendFinishMsg() {
        connection.send(content: "finish".data(using: .utf8), completion: .contentProcessed({sendError in}))
    }
    
    func updateShow() {
        let k: Float = 0.1
        for i in 0 ..< 6 {
            angles[i] += k * (angles_ref[i] - angles[i])
        }
        
        bodyNodes[1].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles[0]) / 180.0)
        bodyNodes[2].rotation = SCNVector4(0, 0, 1, Float.pi * Float(angles[1]) / 180.0)
        bodyNodes[3].rotation = SCNVector4(0, 0, 1, -Float.pi * Float(angles[2]) / 180.0 + 2*Float.pi)
        bodyNodes[4].rotation = SCNVector4(0, 0, 1, -Float.pi * Float(angles[3]) / 180.0 + Float.pi/2)
        
        endefectorNodes[0].rotation = SCNVector4(1, 0, 0, Float.pi * Float(angles[4]) / 180.0 - Float.pi/2)
        endefectorNodes[1].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles[5]) / 180.0 - 3*Float.pi/4)
        endefectorNodes[2].rotation = SCNVector4(0, 1, 0, -Float.pi * Float(angles[5]) / 180.0 + 3*Float.pi/4)
        endefectorNodes[3].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles[5]) / 180.0 - 3*Float.pi/4)
        endefectorNodes[4].rotation = SCNVector4(0, 1, 0, -Float.pi * Float(angles[5]) / 180.0 + 3*Float.pi/4)
        endefectorNodes[5].rotation = SCNVector4(0, 1, 0, -Float.pi * Float(angles[5]) / 180.0 + 3*Float.pi/4)
        endefectorNodes[6].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles[5]) / 180.0 - 3*Float.pi/4)
        
        bodyNodesRef[1].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles_ref[0]) / 180.0)
        bodyNodesRef[2].rotation = SCNVector4(0, 0, 1, Float.pi * Float(angles_ref[1]) / 180.0)
        bodyNodesRef[3].rotation = SCNVector4(0, 0, 1, -Float.pi * Float(angles_ref[2]) / 180.0 + 2*Float.pi)
        bodyNodesRef[4].rotation = SCNVector4(0, 0, 1, -Float.pi * Float(angles_ref[3]) / 180.0 + Float.pi/2)
        bodyNodesRef[5].rotation = SCNVector4(1, 0, 0, Float.pi * Float(angles[4]) / 180.0 - Float.pi/2)
        bodyNodesRef[6].rotation = SCNVector4(0, 1, 0, Float.pi * Float(angles[5]) / 180.0 - 3*Float.pi/4)
        
        let fk = self.forwardKinematics()
        graspNode.transform = fk.actual
        graspNodeRef.transform = fk.ref
        
        self.setValuesForIKLabels()
        
        //self.test()
    }
    
    func forwardKinematics() -> (actual: SCNMatrix4, ref: SCNMatrix4) {
        var T = SCNMatrix4Identity
        for bodyNode in bodyNodes {
            T = SCNMatrix4Mult(bodyNode.transform, T)
        }
        T = SCNMatrix4Mult(endefectorNodes[0].transform, T)
        T = SCNMatrix4Mult(endefectorNodes[7].transform, T)
        
        var T_ref = SCNMatrix4Identity
        for bodyNodeRef in bodyNodesRef {
            T_ref = SCNMatrix4Mult(bodyNodeRef.transform, T_ref)
        }
        return (actual: T, ref: T_ref)
    }
    
    func inverseKinematics(x: Float, y: Float, z: Float, phi_x: Float, phi_y: Float) -> (canSolve: Bool, refAngles: [Float]) {
        var refAngles: [Float] = [90, 90, 90, 90, 90]
        
        var canSolve: Bool = true
        
        refAngles[4] = phi_x + 90.0
        
        //円筒座標系に変換
        let r = sqrt(pow(x - x_origin, 2) + pow(y - y_origin, 2) - pow(delta_y, 2))
        let h = z - z_origin
        let phi_z = atan2(delta_y, r) + atan2(y - y_origin, x - x_origin)
        
        let delta: Float = 10e-3
        if !(phi_z >= -(Float.pi/2 + delta) && phi_z <= Float.pi/2 + delta) { canSolve = false }
        refAngles[0] = 180 * phi_z / Float.pi + 90
        
        //ジョイント4の位置r4, h4を計算
        let r4 = r - k1 * cos(Float.pi * Float(phi_y) / 180) + k2 * sin(Float.pi * phi_y / 180)
        let h4 = h - k1 * sin(Float.pi * Float(phi_y) / 180) - k2 * cos(Float.pi * phi_y / 180)
        
        //cosθ3を計算→θ3を計算
        let c = (pow(r4, 2) + pow(h4, 2) - pow(l_1, 2) - pow(l_2, 2)) / (2.0 * l_1 * l_2)
        var theta_3: Float = 0.0
        if !(c >= -1 && c <= 1) { canSolve = false }
        else {
            theta_3 = acos(c)
            refAngles[2] = 180 * theta_3 / Float.pi
            
            //θ2を計算
            let c2 = (pow(r4, 2) + pow(h4, 2) + pow(l_1, 2) - pow(l_2, 2)) / (2.0 * l_1 * sqrt(pow(r4, 2) + pow(h4, 2)))
            if !(c2 >= -1 && c2 <= 1) { canSolve = false }
            else {
                let theta_2 = acos(c2) + atan2(h4, r4)
                let theta_4 = theta_2 - theta_3 + Float.pi / 2 - (Float.pi * phi_y / 180)
                refAngles[1] = 180 * theta_2 / Float.pi
                refAngles[3] = 180 * theta_4 / Float.pi
            }
        }
        for refAngle in refAngles {
            if refAngle < 0 || refAngle > 180 || !canSolve {
                canSolve = false
                refAngles = [90, 90, 90, 90, 90]
                break
            }
        }
        return (canSolve: canSolve, refAngles: refAngles)
    }
    
    func test() {
        var takeAction: Bool = false
        var a: [Float] = [90, 90, 47, 180, 100, 70]
        if counter % 1600 == 200 {
            a = [90, 90, 47, 180, 100, 70]
            takeAction = true
        }
        if counter % 1600 == 400 {
            a = [90, 47, 47, 180, 100, 70]
            takeAction = true
        }
        if counter % 1600 == 600 {
            a = [90, 47, 47, 180, 100, 135]
            takeAction = true
        }
        if counter % 1600 == 800 {
            a = [90, 90, 47, 180, 100, 135]
            takeAction = true
        }
        if counter % 1600 == 1000 {
            a = [60, 90, 47, 180, 100, 135]
            takeAction = true
        }
        if counter % 1600 == 1200 {
            a = [60, 47, 47, 180, 100, 135]
            takeAction = true
        }
        if counter % 1600 == 1400 {
            a = [60, 47, 47, 180, 100, 70]
            takeAction = true
        }
        if counter % 1600 == 0 && counter != 0 {
            a = [60, 90, 47, 180, 100, 70]
            takeAction = true
        }
        
        if takeAction {
            for i in 0 ..< 6 {
                self.sliders[i].value = a[i]
            }
            self.updateAngles(self)
            self.sendAngleData(self)
        }
        counter += 1
    }
}
