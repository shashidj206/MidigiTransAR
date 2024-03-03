//
//  ViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 21/02/24.
//


import SceneKit
import UIKit
import ARKit

class ARSCNViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var imageNode: SCNNode?
    var selectedImage = UIImage(named: "")
    var detectedPlanes = Set<ARAnchor>()
    
    var viewModel:ARSCNViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configeSceneSession()
        selectedImage = UIImage(named: self.viewModel?.paginationData.first ?? "")
        self.addGestures()
        //self.setupUI()
    }
    
    func setSelectedImage(image: UIImage) {
        selectedImage = image
        // Update the material of the plane node with the selected image
        if let planeNode = imageNode {
            let material = SCNMaterial()
            material.diffuse.contents = selectedImage
            planeNode.geometry?.firstMaterial = material
        }
    }
    
    private func configeSceneSession(){
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        //self.newScanButton.isHidden = false
    }
    
    private func addGestures(){
        // Add pinch and rotation, pan gesture recognizers
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // Ensure gestures are forwarded properly
        for gestureRecognizer in sceneView.gestureRecognizers ?? [] {
            gestureRecognizer.delegate = self
        }
    }
}

// MARK: ARSCNViewDelegate
extension ARSCNViewController{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //        print("didAdd")
        //        print(detectedPlanes)
        //        print(anchor)
        
        // Check if the anchor is of type ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        self.sceneView.debugOptions = []
        
        // Check if this plane has already been detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //        print("didUpdate")
        //        print(detectedPlanes)
        //        print(anchor)
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Check if the updated plane is already detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
}

// MARK: Gestures
extension ARSCNViewController{
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let pinchScaleX = Float(gestureRecognizer.scale) * imageNode.scale.x
        let pinchScaleY = Float(gestureRecognizer.scale) * imageNode.scale.y
        let pinchScaleZ = Float(gestureRecognizer.scale) * imageNode.scale.z
        
        imageNode.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
        
        gestureRecognizer.scale = 1
    }
    
    @objc func handleRotationGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let rotation = Float(gestureRecognizer.rotation)
        
        imageNode.eulerAngles.y -= rotation
        
        gestureRecognizer.rotation = 0
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        switch gestureRecognizer.state {
        case .changed:
            
            let translation = gestureRecognizer.translation(in: sceneView)
            let xTranslation = Float(translation.x) / Float(sceneView.bounds.width) * 2.0 // Adjust multiplier as needed
            let zTranslation = Float(translation.y) / Float(sceneView.bounds.height) * 2.0 // Adjust multiplier as needed
            
            let currentPosition = imageNode.position
            imageNode.position = SCNVector3(currentPosition.x + xTranslation, currentPosition.y, currentPosition.z - zTranslation)
            
            gestureRecognizer.setTranslation(.zero, in: sceneView)
        default:
            break
        }
    }
}

extension ARSCNViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
