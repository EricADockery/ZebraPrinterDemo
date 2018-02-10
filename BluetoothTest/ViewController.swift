//
//  ViewController.swift
//  BluetoothTest
//
//  Created by Eric Dockery on 1/22/18.
//  Copyright © 2018 Eric Dockery. All rights reserved.
//

import UIKit

class ViewController: UIViewController  {


    @IBOutlet var printerConnectionStatus: UILabel!
    var printManager = PrintManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        printManager.connectionDelegate = self
        if printManager.isConnected {
            printerConnectionStatus.text = "Connected"
        } else {
            printerConnectionStatus.text = "Not Connected"
        }
    }

    @IBAction func printTestLabel(_ sender: Any) {
        printManager.printBarcode(for: "This is a test")
    }

}

extension ViewController: EAAccessoryManagerConnectionStatusDelegate {
    func changeLabelStatus() {
        if printManager.isConnected {
            printerConnectionStatus.text = "Connected"
        } else {
            printerConnectionStatus.text = "Not Connected"
        }
    }
}
