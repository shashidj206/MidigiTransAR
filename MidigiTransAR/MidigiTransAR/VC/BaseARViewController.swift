//
//  BaseARViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 03/03/24.
//

import UIKit
import ARKit

class BaseARViewController: UIViewController {
    // Container view to hold ARSCNViewController's view
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var scanFloorView: UIView!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var newScanButton: UIButton!
    @IBOutlet var galleryButton: UIButton!

    var collectionVC: ARCollectionList?
    var isImageSelected = false
    var isCollectionViewVisible = false

    // Instance of ARSCNViewController
    var arSceneViewController: ARSCNViewController?
    var viewModel = ARSCNViewModel()

    // Add a new UIViewController
    func addChildViewController(newViewController: ARCollectionList) {
        // Check if the new view controller already has a parent view controller
        guard newViewController.parent == nil else {
            return // Do nothing if the view controller already has a parent
        }
        
        self.collectionVC = newViewController
        self.collectionVC?.viewModel = self.viewModel
        self.collectionVC?.delegate = self
        
        let buttonFrame = self.settingButton?.frame ?? CGRect.zero
        
        self.collectionVC?.modalPresentationStyle = .popover

        // Present popover
        if let popoverPresentationController = self.collectionVC?.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = buttonFrame
            //popoverPresentationController.delegate = self
            if let popoverController = self.collectionVC {
                present(popoverController, animated: true, completion: nil)
            }
        }
    }

    // Remove the currently added UIViewController
    func removeChildViewController() {
        self.collectionVC?.willMove(toParent: nil)
        self.collectionVC?.view.removeFromSuperview()
        self.collectionVC?.removeFromParent()
        self.collectionVC = nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let vc = self.collectionVC {
            self.dismiss(animated: true)
        }
    }
    
    // Method to add ARSCNViewController to the container view
    func addARSceneViewController() {
        if let vc = self.storyboard?.instantiateViewController(identifier: "ARSCNViewController") as? ARSCNViewController {
            self.arSceneViewController = vc
            self.arSceneViewController?.viewModel = self.viewModel
            addChild(arSceneViewController!)
            containerView.addSubview(arSceneViewController!.view)
            arSceneViewController!.view.frame = containerView.bounds
            arSceneViewController!.didMove(toParent: self)
        }
        
    }
    
    @IBAction func openGalleryAction(_ sender: Any) {
        self.openGallery()
    }

    @IBAction func newScanAction(_ sender: Any) {
        self.addARSceneViewController()
    }
    
    @IBAction func settingAction(_ sender: Any) {
        if let vc = self.storyboard?.instantiateViewController(identifier: "ARCollectionList") as? ARCollectionList {
            self.addChildViewController(newViewController: vc)
        }
    }
    
    @IBAction func scanfloorAction(_ sender: Any) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            // Camera access already granted
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.scanFloorView.isHidden = true
                self.newScanButton.isHidden = false
                self.galleryButton.isHidden = false
                self.addARSceneViewController()
            })
            break
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // Camera access granted
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = true
                        self.newScanButton.isHidden = false
                        self.galleryButton.isHidden = false
                        self.addARSceneViewController()
                    })
                } else {
                    // Camera access denied
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = false
                        self.newScanButton.isHidden = true
                        self.galleryButton.isHidden = true
                        self.showCameraPermissionAlert()
                    })
                }
            }
        case .denied, .restricted:
            // Camera access denied or restricted
            DispatchQueue.main.async{
                self.showCameraPermissionAlert()
            }
            break
        @unknown default:
            break
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true, completion: nil)
    }
}

extension BaseARViewController:ARCollectionListDelegate{
    func setSelectedImage(image: UIImage) {
        isImageSelected = true
        isCollectionViewVisible = false
        self.dismiss(animated: true)
        // Update the material of the plane node with the selected image
        arSceneViewController?.setSelectedImage(image: image)
    }
}

extension BaseARViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension BaseARViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Function to open the photo gallery
    func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerControllerDelegate method to handle when an image is picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Do something with the picked image, like displaying it in an image view
            // For example:
            // imageView.image = pickedImage
            self.setSelectedImage(image: pickedImage)
        }
        
        picker.dismiss(animated: true, completion: nil) // Dismiss the picker
    }
    
    // UIImagePickerControllerDelegate method to handle when the user cancels picking an image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil) // Dismiss the picker
    }
}
