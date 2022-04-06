//
//  QRCoder.swift
//  ScreenShare
//
//  Created by 李方长 on 2022/4/6.
//

import Foundation
import UIKit
import AVFoundation

let kScreenHeight = UIScreen.main.bounds.height
let kScreenWidth = UIScreen.main.bounds.width

protocol QRCoderViewControllerDelegate:AnyObject {
    func qrCoderViewColler(_ vc:QRCoderViewController, result:[String])
}

class QRCoderViewController:UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    weak open var delegate:QRCoderViewControllerDelegate? = nil
    
    lazy var scanImageView:UIImageView = {
        let view = UIImageView.init(frame: view.frame)
        return view
    }()
    
    lazy var backButton:UIButton = {
        let btn = UIButton()
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 2
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 50/2
        btn.setTitle("返回", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return btn
    }()
    
    let session = AVCaptureSession()
    
    private func addScaningVideo(){
        //1.获取输入设备（摄像头）
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        //2.根据输入设备创建输入对象
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }

        //3.创建原数据的输出对象
        let metadataOutput = AVCaptureMetadataOutput()
        
        //4.设置代理监听输出对象输出的数据，在主线程中刷新
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        //5.创建会话（桥梁）
//        let session = AVCaptureSession()
        
        //6.添加输入和输出到会话
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        //7.告诉输出对象要输出什么样的数据(二维码还是条形码),要先创建会话才能设置
        metadataOutput.metadataObjectTypes = [.qr, .code128, .code39, .code93, .code39Mod43, .ean8, .ean13, .upce, .pdf417, .aztec]
        
        //8.创建预览图层
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        //9.设置有效扫描区域(默认整个屏幕区域)（每个取值0~1, 以屏幕右上角为坐标原点）
        let rect = CGRect(x: scanImageView.frame.minY / kScreenHeight, y: scanImageView.frame.minX / kScreenWidth, width: scanImageView.frame.height / kScreenHeight, height: scanImageView.frame.width / kScreenWidth)
        metadataOutput.rectOfInterest = rect
        
        //10. 开始扫描
        session.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //1. 取出扫描到的数据: metadataObjects
        //2. 以震动的形式告知用户扫描成功
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        //3. 关闭session
        session.stopRunning()
        
        //4. 遍历结果
        var resultArr = [String]()
        for result in metadataObjects {
            //转换成机器可读的编码数据
            if let code = result as? AVMetadataMachineReadableCodeObject {
                resultArr.append(code.stringValue ?? "")
            }else {
                resultArr.append(result.type.rawValue)
            }
        }
        
        print("result:", resultArr)
        //5. 将结果
        self.delegate?.qrCoderViewColler(self, result: resultArr)
        self.dismiss(animated: true)
        
    }
    
    @objc private func backAction() {
        dismiss(animated: false)
    }
    
    private func setupSubviews() {
        view.addSubview(scanImageView)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 100, height: 50))
            make.left.equalTo(view).offset(50)
            make.bottom.equalTo(view).offset(-50)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        addScaningVideo()
    }
    
}

class QRCoderView:UIView {
        
    lazy var imageView:UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    init(_ image: UIImage) {
        super.init(frame: CGRect.zero)
        self.imageView.image = image
        backgroundColor = .gray
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 200, height: 200))
            make.center.equalTo(self)
        }
        addGesture()
    }
    
    private func addGesture() {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(gestureAction))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        addGestureRecognizer(tap)
    }
    
    @objc private func gestureAction() {
        removeFromSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

class QRCoder {
    
    class func recognitionQRCode(qrCodeImage: UIImage) -> [String]? {
        //1. 创建过滤器
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        
        //2. 获取CIImage
        guard let ciImage = CIImage(image: qrCodeImage) else { return nil }
        
        //3. 识别二维码
        guard let features = detector?.features(in: ciImage) else { return nil }
        
        //4. 遍历数组, 获取信息
        var resultArr = [String]()
        for feature in features {
            resultArr.append(feature.type)
        }
        
        return resultArr
    }
    
    class func creatQRImage(_ str:String) -> UIImage {
        /// CIFilter
        let filter = CIFilter.init(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        /// Add Data
        //链接转换
        let data = str.data(using: .utf8)
        filter?.setValue(data, forKeyPath: "inputMessage")
        /// Out Put
        let outputImage = filter?.outputImage
        /// Show QRCode
        return QRCoder.createUIImageFromCIImage(image: outputImage!, size: 50)
    }

     private static func createUIImageFromCIImage(image: CIImage, size: CGFloat) -> UIImage {
        let extent = image.extent.integral
        let scale = min(size / extent.width, size / extent.height)
        
        /// Create bitmap
        let width: size_t = size_t(extent.width * scale)
        let height: size_t = size_t(extent.height * scale)
        let cs: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmap: CGContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: 1)!
        
        ///
        let context = CIContext.init()
        let bitmapImage = context.createCGImage(image, from: extent)
        bitmap.interpolationQuality = .none
        bitmap.scaleBy(x: scale, y: scale)
        bitmap.draw(bitmapImage!, in: extent)
        
        let scaledImage = bitmap.makeImage()
        return UIImage.init(cgImage: scaledImage!)
    }
    
}
