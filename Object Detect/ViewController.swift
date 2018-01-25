//
//  ViewController.swift
//  Object Detect
//
//  Created by Vitaliy Krynytskyy on 25/01/2018.
//  Copyright © 2018 Vitaliy Krynytskyy. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start up the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080 // change to use 120fps camera

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }

        captureSession.addInput(deviceInput)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        
        // output monitor
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupIdentifierConfidenceLabel()
        
    }
    
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //print("camera was abe to capture a frame", Date()) // triggers once a camera frame has been detected/ captured
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // ###### download the model here: https://coreml.store/vgg16 and import into the project ######
        guard let model = try? VNCoreMLModel(for: VGG16().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            // check the error
            
            //print(finishedReq.results) // show all results
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            //print(firstObservation.identifier, firstObservation.confidence) // only show first result with the % confidence
            
            DispatchQueue.main.async {
                self.identifierLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

