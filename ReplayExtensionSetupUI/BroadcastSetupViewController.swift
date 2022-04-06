//
//  BroadcastSetupViewController.swift
//  ReplayExtensionSetupUI
//
//  Created by 李方长 on 2022/4/4.
//

import ReplayKit

class BroadcastSetupViewController: UIViewController {

    // Call this method when the user has finished interacting with the view controller and a broadcast stream can start
    func userDidFinishSetup() {
        // URL of the resource where broadcast can be viewed that will be returned to the application
        let broadcastURL = URL(string:"http://apple.com/broadcast/streamID")
        
        // Dictionary with setup information that will be provided to broadcast extension when broadcast is started
        let setupInfo: [String : NSCoding & NSObjectProtocol] = ["broadcastName": "example" as NSCoding & NSObjectProtocol]
        
        // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
        self.extensionContext?.completeRequest(withBroadcast: broadcastURL!, setupInfo: setupInfo)
    }
    
    func userDidCancelSetup() {
        let error = NSError(domain: "YouAppDomain", code: -1, userInfo: nil)
        // Tell ReplayKit that the extension was cancelled by the user
        self.extensionContext?.cancelRequest(withError: error)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red
        let button = UIButton.init(frame: CGRect.init(x: 100, y: 100, width: 200, height: 100))
        button.addTarget(self, action:#selector(buttonAction) , for: .touchUpInside)
        button.backgroundColor = UIColor.yellow
        view.addSubview(button)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("UI:didAppear")
        self.userDidFinishSetup()
    }
    
    @objc private func buttonAction() {
        userDidFinishSetup()
    }
    
}
