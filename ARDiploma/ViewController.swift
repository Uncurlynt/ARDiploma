//
//  ViewController.swift
//  ARDiploma
//
//  Created by Артемий Андреев  on 17.01.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!

    var modelNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("View did load")

        sceneView.delegate = self

        // ARSessionDelegate для отслеживания состояния камеры
        sceneView.session.delegate = self
        sceneView.showsStatistics = true

        // Настройки освещения
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("View will appear")

        let configuration = ARImageTrackingConfiguration()
        
        if let imageToTrack = ARReferenceImage.referenceImages(inGroupNamed: "Cards", bundle: Bundle.main) {
            configuration.trackingImages = imageToTrack
            configuration.maximumNumberOfTrackedImages = 2
        } else {
            print("Failed to load reference images")
        }
        
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("View will disappear")
        
        sceneView.session.pause()
    }

    // MARK: - Кнопка "Сброс" для перезапуска сессии
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        let configuration = ARImageTrackingConfiguration()
        if let imageToTrack = ARReferenceImage.referenceImages(inGroupNamed: "Cards", bundle: Bundle.main) {
            configuration.trackingImages = imageToTrack
            configuration.maximumNumberOfTrackedImages = 2
        }
        // Сбрасываем трекинг и удаляем якори
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("AR session has been reset")
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("Renderer called for anchor: \(anchor)")
        
        let node = SCNNode()
        
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("Anchor is not an image anchor")
            return node
        }
        
        let plane = SCNPlane(
            width: imageAnchor.referenceImage.physicalSize.width,
            height: imageAnchor.referenceImage.physicalSize.height
        )
        plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)

        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)

        if imageAnchor.referenceImage.name == "Card" {
            print("Loading 3D model for 'Card'")

            guard let pokeScene = SCNScene(named: "art.scnassets/Microscope.scn") else {
                print("Failed to load SCNScene named 'Microscope'")
                showErrorAlert(message: "Не удалось загрузить 3D-модель Microscope.scn")
                return node
            }

            guard let pokeNode = pokeScene.rootNode.childNodes.first else {
                print("Failed to find child node in 3D model")
                return node
            }

            print("Successfully loaded 3D model")

            // Исправление ориентации
            pokeNode.eulerAngles.x = .pi / 2
            pokeNode.scale = SCNVector3(2.0, 2.0, 2.0)
            pokeNode.position = SCNVector3(0, 0, 5)

            //Анимация
            pokeNode.opacity = 0
            pokeNode.runAction(SCNAction.fadeIn(duration: 0.5))

            modelNode = pokeNode

            planeNode.addChildNode(pokeNode)
        }
        
        return node
    }

    // MARK: - ARSessionDelegate (Отслеживание состояния камеры)
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Tracking not available")
        case .limited(let reason):
            print("Tracking limited: \(reason)")
        case .normal:
            print("Tracking normal")
        }
    }
    
    // MARK: - Обработка ошибок
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Жесты

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let node = modelNode else { return }
        
        let translation = gesture.translation(in: sceneView)

        if gesture.numberOfTouches == 1 {
            let rotationSpeed: Float = .pi / 180
            let xRotation = Float(translation.y) * rotationSpeed
            let yRotation = Float(translation.x) * rotationSpeed
            
            node.eulerAngles.x += xRotation
            node.eulerAngles.y += yRotation
        } else if gesture.numberOfTouches == 2 {
            let moveSpeed: Float = 0.001
            let xMove = Float(translation.x) * moveSpeed
            let yMove = Float(translation.y) * moveSpeed
            node.position.x += xMove
            node.position.y -= yMove
        }
        
        gesture.setTranslation(.zero, in: sceneView)
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let node = modelNode else { return }
        
        if gesture.state == .changed || gesture.state == .began {
            let scale = Float(gesture.scale)
            node.scale = SCNVector3(
                node.scale.x * scale,
                node.scale.y * scale,
                node.scale.z * scale
            )
            gesture.scale = 1
        }
    }
}
