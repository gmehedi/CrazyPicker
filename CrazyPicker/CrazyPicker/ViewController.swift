//
//  ViewController.swift
//  CrazyPicker
//
//  Created by Mehedi Hasan on 16/2/22.
//

import UIKit
import Photos
import AVKit
import PhotosUI
import LightCompressor


public enum PHAssetMediaType : Int {
    case Unknown
    case Image
    case Video
    case Audio
}


class ViewController: UIViewController {
    
    @IBOutlet weak var topCView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let vc = CrazyPicker()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.fetchAllPHAsset()
        
    }
    
    @IBAction func tappedOnPicker(_ sender: Any) {
        self.showPhotos()
        
    }
    func showPhotos() {
        if #available(iOS 14, *) {
            pickPhoto(limit: 1, delegate: self)
        } else {
            // Fallback on earlier versions
            openGallary()
        }
        print("open photoLibary")
    }
    
    
}

@available(iOS 14, *)
extension ViewController: PHPickerViewControllerDelegate {
    
    func pickPhoto(limit : Int , delegate : PHPickerViewControllerDelegate){
        // new in iOS 14, we can get the asset _later_ so we don't need access up front
        do {
            // if you create the configuration with no photo library, you will not get asset identifiers
            var config = PHPickerConfiguration()
            // try it _with_ the library
            config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            config.selectionLimit = limit // default
            // what you filter out will indeed not appear in the picker
            config.filter = .any(of: [.images , .livePhotos, .videos]) // default is all three appear, no filter
            config.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = delegate
            // works okay as a popover but even better just present, it will be a normal sheet
            self.present(picker, animated: true)
            // PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        }
    }
    
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard results.first != nil else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        picker.dismiss(animated: true) {
            let prov = results.first!.itemProvider
            
            prov.loadObject(ofClass: UIImage.self) { im, err in
                if let image = im as? UIImage {
                    // do whatever action with your image here
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                }
            }
            
            prov.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, err in
                guard let videoURL = url as? URL else {
                    
                    
                    return
                }
                
                
                let fm = FileManager.default
                let uuid = UUID().uuidString
                
                let destination = self.getDocumentsDirectory().appendingPathComponent(uuid + "v.mp4")
                
                
                try! fm.copyItem(at: videoURL, to: destination)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0, execute: {
                    let aset2  = AVURLAsset(url: destination) // t works
                    let size = Int64(aset2.fileSize ?? 0)
                    //print("Asset555 ",Units(bytes: size).getReadableUnit(),"  ", aset2.duration.seconds,"     ", aset2.screenSize)
                    
                    
                    let fm = FileManager.default
                    let uuid = UUID().uuidString
                    
                    let destination2 = fm.temporaryDirectory.appendingPathComponent(uuid + "video1.mp4")
                    
                    let videoCompressor = LightCompressor()
                     
                    let compression: Compression = videoCompressor.compressVideo(
                                                    source: destination,
                                                    destination: destination2,
                                                    quality: .medium,
                                                    isMinBitRateEnabled: false,
                                                    keepOriginalResolution: false,
                                                    progressQueue: .main,
                                                    progressHandler: { progress in
                                                        // progress
                                                        print("Progress  ", progress.completedUnitCount)
                                                    },
                                                    completion: {[weak self] result in
                                                        guard let `self` = self else { return }
                                                                 
                                                        switch result {
                                                        case .onSuccess(let path):
                                                            
                                                            let url = path
                                                            let aset2  = AVURLAsset(url: url)
                                                            let size = Int64(aset2.fileSize ?? 0)
                                                            print("Asset666 ",Units(bytes: size).getReadableUnit(),"  ", aset2.duration.seconds,"     ", aset2.screenSize)
                                                            
                                                            //print("Asset555444 ",Units(bytes: size).getReadableUnit(),"  ", aset2.duration.seconds,"     ", aset2.screenSize)
                                                            break
                                                            // success
                                                                     
                                                        case .onStart:
                                                            // when compression starts
                                                             print("ComStart")
                                                            break
                                                        case .onFailure(let error):
                                                            // failure error
                                                            print("ComEnd  ", error)
                                                            break
                                                        case .onCancelled:
                                                            // if cancelled
                                                            print("ComCancell")
                                                            break
                                                        }
                                                    }
                     )
           
                })
            }

        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
}

extension ViewController {
    
    func openGallary() {
        let localUIPicker = UIImagePickerController()
        localUIPicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            localUIPicker.allowsEditing = false
            localUIPicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(localUIPicker, animated: true, completion: {})
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let choosenLogo = info[.originalImage] as? UIImage else {
            return
        }
        // do whatever action with your image here
        
        
    }
}



extension ViewController {
    
    func fetchAllPHAsset() {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                         ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                             PHAssetMediaSubtype.photoLive.rawValue,
                                             PHAssetMediaSubtype.photoHDR.rawValue,
                                             PHAssetMediaSubtype.photoPanorama.rawValue,
                                             
                                             PHAssetMediaSubtype.photoScreenshot.rawValue,
                                             PHAssetMediaSubtype.photoDepthEffect.rawValue,
                                             
                                             PHAssetMediaSubtype.videoStreamed.rawValue)
        fetchOptions.fetchLimit = 100


        let allMedia = PHAsset.fetchAssets(with: fetchOptions)
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let allVideo = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        let assets = PHAsset.fetchAssets(with: .image, options: nil)
        print("Found \(allMedia.count) media")
        print("Found \(allPhotos.count) images", assets.count)
        print("Found \(allVideo.count) videos")
    }
    
    
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
    
    var screenSize: CGSize? {
        if let track = tracks(withMediaType: .video).first {
            let size = __CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        }
        return nil
    }
}


public struct Units {
  
  public let bytes: Int64
  
  public var kilobytes: Double {
    return Double(bytes) / 1_024
  }
  
  public var megabytes: Double {
    return kilobytes / 1_024
  }
  
  public var gigabytes: Double {
    return megabytes / 1_024
  }
  
  public init(bytes: Int64) {
    self.bytes = bytes
  }
  
  public func getReadableUnit() -> String {
    
    switch bytes {
    case 0..<1_024:
      return "\(bytes) bytes"
    case 1_024..<(1_024 * 1_024):
      return "\(String(format: "%.2f", kilobytes)) kb"
    case 1_024..<(1_024 * 1_024 * 1_024):
      return "\(String(format: "%.2f", megabytes)) mb"
    case (1_024 * 1_024 * 1_024)...Int64.max:
      return "\(String(format: "%.2f", gigabytes)) gb"
    default:
      return "\(bytes) bytes"
    }
  }
}




