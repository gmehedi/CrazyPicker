//
//  CrazyPicker.swift
//  CrazyPicker
//
//  Created by Mehedi Hasan on 17/2/22.
//

import UIKit
import Photos
import AVKit
import PhotosUI
import LightCompressor


class CrazyPicker: UIViewController {
    
    
    @IBOutlet weak var pickerCollectionView: UICollectionView!
    let manager = PHImageManager.default()
    
    var allMedia = PHFetchResult<PHAsset>()
    var allPhotos = PHFetchResult<PHAsset>()
    var allVideo = PHFetchResult<PHAsset>()
    var allVideoAsset = [AVURLAsset]()
    
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchAllPHAsset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        self.setupCollectionView()
    }
    
    @IBAction func changeSegmentControlState(_ sender: UISegmentedControl) {
        
        self.selectedIndex = sender.selectedSegmentIndex
        
        switch sender.selectedSegmentIndex {
        case 0:
            break
        default:
            break
        }
        self.pickerCollectionView.reloadData()
    }
    
}

extension CrazyPicker {
    
    func setupCollectionView() {
        self.registerCollectionViewCell()
        self.setCollectionViewFlowLayout()
        self.setCollectionViewDelegate()
    }
    
    //MARK: Registration nib file and Set Delegate, Datasource
    fileprivate func registerCollectionViewCell(){
        self.pickerCollectionView.register(UINib(nibName: PickerThumCell.id, bundle: nil), forCellWithReuseIdentifier: PickerThumCell.id)
    }
    
    //MARK: Set Collection View Flow Layout
    fileprivate func setCollectionViewFlowLayout(){
        
        if let layoutMenu1 = self.pickerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout{
            layoutMenu1.scrollDirection = .vertical
            layoutMenu1.minimumLineSpacing = 10
            layoutMenu1.minimumInteritemSpacing = 10
        }
        self.pickerCollectionView.contentInset = UIEdgeInsets(top: 33, left: 20, bottom: 0, right: 20)
    
        
    }
    
    //MARK: Set Collection View Delegate
    fileprivate func setCollectionViewDelegate() {
        self.pickerCollectionView.delegate = self
        self.pickerCollectionView.dataSource = self
    }
}

//MARK: - UICollectionViewDataSource
extension CrazyPicker: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case pickerCollectionView:
            
            switch self.selectedIndex {
            case 0:
                return self.allPhotos.count
            default:
                return self.allVideo.count
            }
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case pickerCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PickerThumCell.id, for: indexPath) as! PickerThumCell
            switch self.selectedIndex {
            case 0:
                cell.imageView.image = self.allPhotos[indexPath.item].thumbnailImage
                cell.durationLabel.alpha = 0
                break
            case 1:
                cell.durationLabel.alpha = 1
                cell.imageView.image = self.allVideo[indexPath.item].thumbnailImage
                if self.allVideoAsset.count > indexPath.item {
                    let time = round(self.allVideoAsset[indexPath.item].duration.seconds * 100.0) / 100.0
                    cell.durationLabel.text = time.getTimePattern()
                }
               
                break
            default:
                break
            }
            
            
            return cell
        default:
            return UICollectionViewCell()
        }
   
    }
}

//MARK: - UICollectionViewDelegate
extension CrazyPicker: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch self.selectedIndex {
        case 0:
            let vc = OutputVC()
            vc.selectedImage = self.allPhotos[indexPath.item].getUIImage()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case 1:
            let vc = OutputVC()
             vc.selectedAsset = self.allVideoAsset[indexPath.item]
            
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        default:
            break
        }
       
    }
    
    
}

//MARK: - UICollectionViewDelegateFlowLayout
extension CrazyPicker: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 64, height: 64)
    }
}

extension CrazyPicker {
    
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


        self.allMedia = PHAsset.fetchAssets(with: fetchOptions)
        self.allPhotos = PHAsset.fetchAssets(with: .image, options: nil)
        self.allVideo = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        for i in 0 ..< self.allVideo.count {
            let pHAsset = self.allVideo[i]
            
            self.manager.requestAVAsset(forVideo: pHAsset, options: nil) { [weak self] aVAsset, aMix, dic in
                if let ass = aVAsset {
                    
                    self?.allVideoAsset.append(ass as! AVURLAsset)
                    DispatchQueue.main.async {
                        self?.pickerCollectionView.reloadData()
                    }
                }
              
            }
        }
    }
    
}

extension PHAsset {
    
    var thumbnailImage : UIImage {
        get {
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            var thumbnail = UIImage()
            option.isSynchronous = true
            manager.requestImage(for: self, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                thumbnail = result!
            })
            return thumbnail
        }
    }
    
    func getUIImage() -> UIImage? {

        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: self, options: options) { data, _, _, _ in

            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
}

extension Double {
    
    func getTimePattern() -> String {
        
        var minute = Int(self) / 60
        let sec = Int(self) % 60
        
        let hour = minute / 60
        minute = minute % 60
        
        var hString = String(hour)
        var mString = String(minute)
        let sString = String(sec)
        
        if hString.count == 1 {
            hString = "0" + hString
        }
        
        if mString.count == 1 {
            mString = "0" + mString
        }
        
        if sString.count == 1 {
            hString = "0" + sString
        }
        
        let res = hString + ":" + mString + ":" + sString
        
        return res

    }
}
