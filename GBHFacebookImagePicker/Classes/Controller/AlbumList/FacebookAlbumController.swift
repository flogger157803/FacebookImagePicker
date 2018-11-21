//
//  FacebookAlbumController.swift
//  GBHFacebookImagePicker
//
//  Created by Florian Gabach on 17/11/2018.
//

import UIKit

final class FacebookAlbumController: UIViewController {
    
    // MARK: - Var
    
    fileprivate lazy var stateViewController = ContentStateViewController()
    
    weak var delegate: FacebookImagePickerDelegate?
    
    fileprivate var facebookController: FacebookController
    
    // MARK: - Lifecycle
    
    init(facebookController: FacebookController) {
        self.facebookController = facebookController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.add(stateViewController)
        
        self.prepareObserver()
        self.prepareController()
        self.prepareCloseButton()
        
        self.doFacebookLogin()
    }
    
    // MARK: - Prepare
    
    fileprivate func prepareController() {
        self.view.backgroundColor = FacebookImagePicker.pickerConfig.uiConfig.backgroundColor
    }
    
    fileprivate func prepareObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didReceiveAlbum),
                                               name: Notification.Name.ImagePickerDidRetrieveAlbum,
                                               object: nil)
    }
    
    fileprivate func prepareCloseButton() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop,
                                          target: self,
                                          action: #selector(self.closePicker))
        closeButton.tintColor = FacebookImagePicker.pickerConfig.uiConfig.closeButtonColor ?? .black
        self.navigationItem.rightBarButtonItem = closeButton
    }
    
    // MARK: - Action
    
    /// Start Facebook login
    fileprivate func doFacebookLogin() {
        self.facebookController.login(controller: self) { (success, error) in
            if !success {
                // Something wrong
                if let loginError = error {
                    switch loginError {
                    case .loginCancelled:
                        // Cancelled login
                        self.delegate?.facebookImagePicker(didCancelled: self)
                        self.dismissPicker()
                    case .loginFailed:
                        // Failed to login with Facebook
                        self.delegate?.facebookImagePicker(imagePicker: self, didFailWithError: error)
                        self.dismissPicker()
                    case .permissionDenied:
                        // "user_photos" permission are denied, we need to ask permission !
                        self.showDeniedPermissionPopup()
                    }
                }
            }
        }
    }
    
    /// Handler for click on close button
    @objc fileprivate func closePicker() {
        self.delegate?.facebookImagePicker(didCancelled: self)
        self.dismissPicker()
    }
    
    fileprivate func showDeniedPermissionPopup() {
        AlertController.showPermissionAlert(fromController: self,
                                            allowCompletionHandler: {
                                                self.doFacebookLogin()
        }, closeCompletionaHandler: {
            self.dismissPicker()
        })
    }
    
    // MARK: - Renders
    
    /// Handler for did retrieve album list
    @objc func didReceiveAlbum(_ sender: Notification) {
        if let albums =  sender.object as? [FacebookAlbum] {
            self.render(albums)
        }
    }
    
    private func render(_ albums: [FacebookAlbum]) {
        let albumsListController = FacebookAlbumListController(albums: albums)
        albumsListController.delegate = self
        self.stateViewController.transition(to: .render(albumsListController))
    }
    
    // MARK: - Navigation
    
    /// Dismiss the picker
    func dismissPicker() {
        DispatchQueue.main.async {
            // Reset flag
            self.facebookController.reset()
            
            // Dismiss and call delegate
            self.dismiss(animated: true, completion: {
                self.delegate?.facebookImagePickerDismissed()
            })
        }
    }
}

extension FacebookAlbumController: FacebookAlbumPickerDelegate {
    func didSelectAlbum(album: FacebookAlbum) {
        let albumController = AlbumDetailController(facebookController: self.facebookController)
        //albumDetailVC.albumPictureDelegate = self
        albumController.album = album
        self.navigationController?.pushViewController(albumController, animated: true)
    }
}

//    // MARK: - FacebookAlbumPickerDelegate
//
//    /// Did selected picture delegate
//    ///
//    /// - parameter imageModels: model of the selected pictures
//    func didSelecPicturesInAlbum(imageModels: [FacebookImage]) {
//
//        var successModels = [FacebookImage]()
//        var errorModels = [FacebookImage]()
//        var errors = [Error?]()
//
//        let downloadGroup = DispatchGroup()
//
//        for imageModel in imageModels {
//            downloadGroup.enter()
//
//            // Download the image from the full size url
//            imageModel.download(completion: { (error) in
//                if error != nil {
//                    // Error case
//                    errors.append(error)
//                    errorModels.append(imageModel)
//                } else {
//                    // Success case
//                    successModels.append(imageModel)
//                }
//
//                downloadGroup.leave()
//            })
//        }
//
//        downloadGroup.notify(queue: .main) {
//            // Call success delegate
//            self.delegate?.facebookImagePicker(
//                imagePicker: self,
//                successImageModels: successModels,
//                errorImageModels: errorModels,
//                errors: errors
//            )
//
//            // Dismiss picker
//            self.dismissPicker()
//        }
//    }
//
//    /// Performed when an error occured
//    ///
//    /// - Parameter error: the happened error
//    func didFailSelectPictureInAlbum(error: Error?) {
//        if let err = error {
//            print(err.localizedDescription)
//        }
//    }
//}
