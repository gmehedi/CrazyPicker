//
//  OutputVC.swift
//  CrazyPicker
//
//  Created by Mehedi Hasan on 17/2/22.
//

import UIKit
import AVFAudio
import AVKit

class OutputVC: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    var player: AVPlayer?
    let context = CIContext()
    var layer: AVPlayerLayer?
    
    var selectedAsset: AVURLAsset?
    var selectedImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.selectedImage
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let ass = self.selectedAsset {
            self.playVideo(asset: ass)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()
    }
    
}

extension OutputVC {
    
    func playVideo(asset: AVAsset) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            
            
            let com = AVMutableVideoComposition(asset: asset) { [weak self] request in
                
                guard let self = self else {
                    request.finish(with: Error.self as! Error)
                    return
                }
                
                let image = request.sourceImage
                var now = image.copy() as! CIImage
                
                //  let trans = CGAffineTransform(scaleX: 0.5, y: 0.5)
                
                now = now.transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))
                print("Size 11  ", image.extent.size)
                
                let filter = CIFilter(name: "CISourceOverCompositing")
                filter?.setValue(image, forKey: kCIInputBackgroundImageKey)
                filter?.setValue(now, forKey: kCIInputImageKey)
                
                
                if var img = filter?.outputImage {
                    
                    request.finish(with: img, context: self.context)
                }else {
                    request.finish(with: request.sourceImage, context: self.context)
                }
                
            }
            
            
            DispatchQueue.main.async {
                self.layer?.videoGravity = .resizeAspect
                
                
                let item = AVPlayerItem(asset: asset)
                item.videoComposition = com
                self.player = AVPlayer(playerItem: item)
                
                self.layer = AVPlayerLayer(player: self.player)
                self.layer?.frame = self.videoView?.bounds ?? .zero
                self.videoView.layer.addSublayer(self.layer!)
                self.player?.volume = 1
                self.player?.play()
            }
            
        }
        
        
    }
}
