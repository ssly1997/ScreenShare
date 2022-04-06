//
//  SampleHandler.swift
//  ReplayExtension
//
//  Created by 李方长 on 2022/4/4.
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler, SocketToolDelegate {
    func clientSocket(_ tool: TCPClientTool, receive contentData: Data) {
        
    }
    
    func clientSocket(_ tool: TCPClientTool, status: ConnectStatus) {
        
    }
    
    
    let client = TCPClient(address: "192.168.101.22", port: 8866)
    var connect = false
    let gcdClient = TCPClientTool.init()

    func startClient() {
        print("🇨🇳start")
        switch client.connect(timeout: 3) {
        case .success:
            connect = true
        case .failure(let error):
            print(error)
        }
    }
    
    func startGCDClient() {
        let groupDefault = UserDefaults.init(suiteName: "group.sdz.screenShare")
        let host = groupDefault?.value(forKey: "sdz_ip_address")
        guard let host = host as? String else {
            return
        }
        connect = TCPClientTool.shareInstance().connect(toHost: host, onPort: 8866, delegate: self)
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        startGCDClient()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    func handleSampleBuffer(_ sampleBuffer:CMSampleBuffer) {
        if connect {
            let image = sampleBufferToImage(sampleBuffer)
            guard let data = image.jpegData(compressionQuality: 0.5) else {
                return
            }
            var size = (data as NSData).length - 100
            let sizeData = Data(bytes: &size, count: 6)
            _ = client.send(data: sizeData)
            _ = client.send(data: data)
            print("size", size)
        }
    }
    
    func gcdHandleVideoSmapleBuffer(_ sampleBuffer:CMSampleBuffer) {
        if connect {
            let image = sampleBufferToImage(sampleBuffer)
            guard let data = image.jpegData(compressionQuality: 0.5) else {
                return
            }
            TCPClientTool.shareInstance().send(data)
        }
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            gcdHandleVideoSmapleBuffer(sampleBuffer)
//            handleSampleBuffer(sampleBuffer)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
        
    }
    
    func sampleBufferToImage(_ sampleBuffer:CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciimage, from: ciimage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image;
    }
    
    func sampleBufferToData(_ sampleBuffer:CMSampleBuffer) -> Data {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)
        let data = NSData(bytes: src_buff, length: bytesPerRow * height)
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return data as Data
    }
}
