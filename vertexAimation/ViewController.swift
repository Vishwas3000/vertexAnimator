import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // The distance at which to place the cube from the camera
    let cubeDistance: Float = 0.5 // You can adjust this value (in meters)
    
    // Animation properties
    var gradientNodes: [SCNNode] = []
    var animationTimer: Timer?
    var progressTime: Double = 2.0
    var currentProgress: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Start the animation timer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable plane detection if needed
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // Stop the animation timer
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        // Get the current camera position and orientation
        guard let frame = sceneView.session.currentFrame else { return }
        
        // Create a transform with the camera position
        let cameraTransform = frame.camera.transform
        
        // Create the gradient cube
        let cube = createGradientCube()
        
        // Position the cube at a fixed distance in front of the camera
        // Using the camera's orientation to determine the direction
        
        // Extract the camera position
        let cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Extract the camera's forward direction vector
        let cameraDirection = SCNVector3(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        )
        
        // Calculate the position at distance Z away from camera in the direction it's facing
        let cubePosition = SCNVector3(
            cameraPosition.x + cameraDirection.x * cubeDistance,
            cameraPosition.y + cameraDirection.y * cubeDistance,
            cameraPosition.z + cameraDirection.z * cubeDistance
        )
        
        // Set the position of the cube
        cube.position = cubePosition
        
        // Add the cube to the scene
        sceneView.scene.rootNode.addChildNode(cube)
        
        // Add to our array of gradient nodes to animate
        gradientNodes.append(cube)
    }
    
    func createGradientCube() -> SCNNode {
        // Create a custom cube geometry for gradient transparency
        let width: CGFloat = 0.1
        let height: CGFloat = 0.1
        let length: CGFloat = 0.1
        currentProgress = 0.0
        
        // Create a box with 6 segments in height to create the gradient effect
        let segments = 12
        let cubeGeometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.0)
        cubeGeometry.heightSegmentCount = 1
        
        // Base color for the cube
        let baseColor = UIColor.blue
        
        // Create a node with the cube geometry
        let cubeNode = SCNNode(geometry: cubeGeometry)
        
        // Create multiple materials for the gradient effect
        var materials: [SCNMaterial] = []
        
        // For each face of the cube (6 faces)
        for faceIndex in 0..<6 {
            let material = SCNMaterial()
            
            // Create a gradient layer for vertical faces
            if faceIndex == 0 || faceIndex == 1 || faceIndex == 2 || faceIndex == 3 {
                // Create a new CAGradientLayer for each face that needs animation
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                
                // Set colors for the gradient (bottom to top)
                gradientLayer.colors = [
                    baseColor.withAlphaComponent(1.0).cgColor,      // Bottom: Fully visible
                    baseColor.withAlphaComponent(0.0).cgColor       // Top: Fully transparent
                ]
                
                // Set initial direction (bottom to top)
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)  // Bottom
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)    // Top
                
                // Render the gradient to a UIImage
                UIGraphicsBeginImageContextWithOptions(gradientLayer.frame.size, false, 0)
                if let context = UIGraphicsGetCurrentContext() {
                    gradientLayer.render(in: context)
                    let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    // Set the image as the material content
                    material.diffuse.contents = gradientImage
                }
                
                // Store the gradient layer in the node's userData dictionary for animation
                // We need to create a unique key for each face
                cubeNode.setValue(gradientLayer, forKey: "gradientLayer\(faceIndex)")
            } else {
                // For top and bottom faces
                if faceIndex == 4 {  // Top face
                    material.diffuse.contents = baseColor.withAlphaComponent(0.0)
                } else {  // Bottom face
                    material.diffuse.contents = baseColor
                }
            }
            
            // Enable transparency
            material.isDoubleSided = true
            material.blendMode = .alpha
            material.lightingModel = .physicallyBased
            material.transparencyMode = .aOne
            
            materials.append(material)
        }
        
        // Assign materials to the cube
        cubeGeometry.materials = materials
        startGradientAnimation()

        return cubeNode
    }
    
    // MARK: - Animation Methods
    
    func startGradientAnimation() {
        // Create a timer to update the animation
        animationTimer = Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(updateGradientAnimation), userInfo: nil, repeats: true)
    }
    
    @objc func updateGradientAnimation() {
        if currentProgress / progressTime >= 1.0 {
            animationTimer?.invalidate()
            return
        }
        // Update animation step
        currentProgress += 0.02
        
        // Loop through each cube node that has been created
        for node in gradientNodes {
            // Update the gradient for each of the 4 side faces
            for faceIndex in 0..<4 {
                // Get the gradient layer for this face
                guard let gradientLayer = node.value(forKey: "gradientLayer\(faceIndex)") as? CAGradientLayer else {
                    continue
                }
                
                // Calculate wave positions using sine wave for organic motion
                
                // Create animated start and end points
                // This will make the gradient move up and down
                let startY = 1.0 - (currentProgress / progressTime)
                let endY = 0.5 - (currentProgress / progressTime)  // Keep the distance between start and end consistent
                let s = min(max(startY, 0), 1)
                let e = min(max(endY, 0), 1)
                // Update gradient points
                gradientLayer.startPoint = CGPoint(x: 0.5, y: s)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: e)
                
                // Render updated gradient to a new image
                UIGraphicsBeginImageContextWithOptions(gradientLayer.frame.size, false, 0)
                if let context = UIGraphicsGetCurrentContext() {
                    gradientLayer.render(in: context)
                    let updatedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    // Update the material with the new gradient image
                    let material = node.geometry?.materials[faceIndex]
                    material?.diffuse.contents = updatedImage
                }
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
