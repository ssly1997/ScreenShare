//
//  ViewController.swift
//  replay
//
//  Created by 李方长 on 2022/4/4.
//

import UIKit
import ReplayKit
import WebKit

class ViewController: UIViewController, SocketToolDelegate, TCPServerToolDelegate, QRCoderViewControllerDelegate {

//    var socketServer:TCPServer = TCPServer.init(address: Tool.getDeviceIPAdress(), port: 8866)
//    var serverRunning:Bool = false
    
    var image:UIImage? = nil
    
    lazy var stackView:UIStackView = {
        let view = UIStackView.init(arrangedSubviews: [connectView, scanButton, showQRButton])
        view.axis = .horizontal
        view.distribution = .equalCentering
        view.alignment = .bottom
        return view
    }()
    
    lazy var containerView:UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()
    
    lazy var imageView:UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        return view
    }()
    
    lazy var QRImageView:UIImageView = {
        let view = UIImageView()
        view.image = QRCoder.creatQRImage(Tool.getDeviceIPAdress())
        return view
    }()
    
    lazy var scanButton:UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .white
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 50/2
        btn.setTitle("扫码连接", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(scanAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var showQRButton:UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .white
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 50/2
        btn.setTitle("展示二维码", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(showQRAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var connectView:UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        return view
    }()
    
    lazy var connectLabel:UILabel = {
        let label = UILabel()
        label.text = "投屏"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    // MARK: qrCoderVC protocl
    func qrCoderViewColler(_ vc: QRCoderViewController, result: [String]) {
        let targetAddress = result.first
        let groupDefault = UserDefaults.init(suiteName: "group.sdz.screenShare")
        groupDefault?.set(targetAddress, forKey: "sdz_ip_address")
    }
    
    // MARK: gcd socket protocol
    func socket(_ tool: TCPServerTool, receive contentData: Data) {
        print("🇨🇳S:receive data:", contentData)
        self.image = UIImage.init(data: contentData)
        if self.image != nil {
            DispatchQueue.main.async {
                if self.image != nil {
                    print("🇨🇳 new image", self.image!.size)
                    let size = self.image!.size
                    let containerScale:CGFloat = self.containerView.bounds.width/self.containerView.bounds.height
                    let scale:CGFloat = size.width/size.height
                    self.imageView.snp.updateConstraints { make in
                        make.center.equalTo(self.containerView)
                        if scale > containerScale {
                            make.size.equalTo(CGSize.init(width: self.containerView.bounds.width, height: self.containerView.bounds.width/scale))
                        } else {
                            make.size.equalTo(CGSize.init(width: self.containerView.bounds.height*scale, height: self.containerView.bounds.height))
                        }
                    }
                    self.imageView.image = self.image!
                }
            }
        }
    }
    
    func replay() {
       
    }
    
    // MARK: btn Action
    
    @objc func showQRAction() {
        let qrCoderview = QRCoderView.init(QRCoder.creatQRImage(Tool.getDeviceIPAdress()))
        self.view.addSubview(qrCoderview)
        qrCoderview.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    @objc func scanAction() {
        let vc = QRCoderViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    
    func startGCDServer() {
        let res = TCPServerTool.shareInstance().listen(onPort: 8866, delegate: self)
        print("🇨🇳",res)
    }
    
    private func setupSubviews() {
        view.addSubview(scanButton)
        view.addSubview(showQRButton)
        view.addSubview(connectView)
        view.addSubview(stackView)
        connectView.addSubview(connectLabel)
        let broadPickerView = RPSystemBroadcastPickerView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
        broadPickerView.preferredExtension = "com.sdz.replay.Upload.sdz"
        self.view.addSubview(broadPickerView)
        view.addSubview(containerView)
        containerView.addSubview(imageView)

        stackView.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-25)
            make.left.equalTo(view).offset(25)
            make.right.equalTo(view).offset(-25)
        }
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(40)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.bottom.equalTo(connectView.snp.top).offset(-20)
        }
        scanButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 100, height: 50))
        }
        showQRButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 100, height: 50))
        }
        broadPickerView.snp.makeConstraints { make in
            make.centerX.equalTo(connectView)
            make.centerY.equalTo(connectView).offset(10)
            make.size.equalTo(CGSize.init(width: 100, height: 100))
        }
        connectView.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 60, height: 80))
        }
        connectLabel.snp.makeConstraints { make in
            make.centerX.equalTo(connectView)
            make.top.equalTo(connectView).offset(5)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.gray

        setupSubviews()
        startGCDServer()
        //        startServer()
        replay()
        
//        let web = WKWebView()
//        web.load(URLRequest.init(url: URL.init(string: "www.baidu.com")!))
        
    }

}

extension Data {
    var length:Int {
        get {
            return (self as NSData).length
        }
    }
}

/* private func startServer() {
 _ = socketServer.listen()
 serverRunning = true
 DispatchQueue.global(qos: .background).async {
     while self.serverRunning {
         let client = self.socketServer.accept()
         print("🇨🇳 accept")
         if let c = client{
             DispatchQueue.global(qos: .background).async {
                 print("🍉")
                 self.handleClient(c: c)
             }
         }
     }
 }
 print("🇨🇳 start server")
}

private func handleClient(c:TCPClient){
 print("🇨🇳 c accpet")
 var data = c.read(6) ?? []
 if data.isEmpty {
     return
 }
 var length:Int = 0
 var tmpData:Data = Data()
 tmpData.append(contentsOf: data)
 (tmpData as NSData).getBytes(&length, length: 6)
 while !data.isEmpty {
     print("🇨🇳 data:", data)
     self.dataBuffer.removeAll()
     if length > 10000000 {
         assert(false, "data error")
     }
     data = c.read(length) ?? []
     self.dataBuffer.append(contentsOf: data)
     print("🇨🇳! data size:", (self.dataBuffer as NSData).length)
     self.image = UIImage.init(data: self.dataBuffer)
     self.dataBuffer.removeAll()
     if self.image != nil {
         DispatchQueue.main.async {
             print("🇨🇳 new image", self.image!.size)
             let scale:CGFloat = 4
             self.imageView.frame = CGRect.init(x: 0, y: 0, width: self.image!.size.width/scale, height: self.image!.size.height/scale)
             self.imageView.image = self.image!
             
         }
     }
     data = c.read(6) ?? []
     tmpData.removeAll()
     tmpData.append(contentsOf: data)
     (tmpData as NSData).getBytes(&length, length: 6)
 }
}*/
