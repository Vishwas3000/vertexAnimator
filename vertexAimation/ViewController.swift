import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // The distance at which to place the cube from the camera
    let cubeDistance: Float = 0.5 // You can adjust this value (in meters)
    
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
    }
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        // Get the current camera position and orientation
        guard let frame = sceneView.session.currentFrame else { return }
        
        // Create a transform with the camera position
        let cameraTransform = frame.camera.transform
        
        // Create the cube
        let cube = createCube()
        
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
    }
    
    func createCube() -> SCNNode {
        // Create a cube geometry
        let cubeGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        
        // Create material for the cube with shader modifier for animation
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        
        // Add shader modifier for bottom-to-top reveal animation
        material.shaderModifiers = [
            SCNShaderModifierEntryPoint.surface: """
            uniform float animationProgress = 0.0;
            
            #pragma body
            
            // Calculate clip boundary based on animation progress (0.0 to 1.0)
            // This will reveal the cube from bottom to top
            float clipBoundary = -0.5 + animationProgress;
            
            // Discard fragments below the current clip boundary
            if (_surface.position.y < clipBoundary) {
                discard_fragment();
            }
            
            // Add glow effect near the reveal boundary
            float distFromBoundary = abs(_surface.position.y - clipBoundary);
            if (distFromBoundary < 0.05) {
                float glowIntensity = 1.0 - (distFromBoundary / 0.05);
                _surface.emission.rgb += float3(0.2, 0.4, 1.0) * glowIntensity;
            }
            """
        ]
        
        // Assign material to the cube (for all sides)
        cubeGeometry.materials = [material, material, material, material, material, material]
        
        // Create a node with the cube geometry
        let cubeNode = SCNNode(geometry: cubeGeometry)
        
        // Animate the appearance
        animateCubeAppearance(cubeNode)
        
        return cubeNode
    }
    
    func animateCubeAppearance(_ cubeNode: SCNNode) {
        // Get the materials from the cube's geometry
        guard let materials = cubeNode.geometry?.materials else { return }
        
        // Set the initial animation progress to 0
        for material in materials {
            material.setValue(0.0, forKey: "animationProgress")
        }
        
        // Create animation action
        let animationDuration: TimeInterval = 10.0
        
        // Create an animation that changes the shader parameter over time
        let animation = SCNAction.customAction(duration: animationDuration) { (node, elapsedTime) in
            let progress = Float(elapsedTime / animationDuration)
            
            // Update animation progress for all materials
            for material in materials {
                material.setValue(progress, forKey: "animationProgress")
            }
        }
        
        // Run the animation
        cubeNode.runAction(animation)
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
