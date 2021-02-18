//
//  PrintManager.swift
//  BluetoothTest
//
//  Created by Eric Dockery on 1/22/18.
//  Copyright © 2018 Eric Dockery. All rights reserved.
//

import ExternalAccessory

protocol EAAccessoryManagerConnectionStatusDelegate {
    func changeLabelStatus() -> Void
}

enum CommonPrintingFormat: String {
    case start = "! 0 200 200 150 1"
    case end = "\nFORM\nPRINT\n"
}

class PrintManager: NSObject {

    var manager: EAAccessoryManager!
    var isConnected: Bool = false
    var connectionDelegate: EAAccessoryManagerConnectionStatusDelegate?
    private var printerConnection: MfiBtPrinterConnection?
    private var serialNumber: String?
    private var disconnectNotificationObserver: NSObjectProtocol?
    private var connectedNotificationObserver: NSObjectProtocol?
    static let sharedInstance = PrintManager()

    private override init() {
        super.init()
        manager = EAAccessoryManager.shared()
        self.findConnectedPrinter { [weak self] bool in
            if let strongSelf = self {
                strongSelf.isConnected = bool
            }
        }
        //Notifications
        disconnectNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.EAAccessoryDidDisconnect, object: nil, queue: nil, using: didDisconnect)

        connectedNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.EAAccessoryDidConnect, object: nil, queue: nil, using: didConnect)
        manager.registerForLocalNotifications()

    }

    deinit {
        if let disconnectNotificationObserver = disconnectNotificationObserver {
            NotificationCenter.default.removeObserver(disconnectNotificationObserver)
        }
        if let connectedNotificationObserver = connectedNotificationObserver {
            NotificationCenter.default.removeObserver(connectedNotificationObserver)
        }
    }

    func findConnectedPrinter(completion: (Bool) -> Void) {
        let connectedDevices = manager.connectedAccessories
        for device in connectedDevices {
            if device.protocolStrings.contains("com.zebra.rawport") {
                serialNumber = device.serialNumber
                connectToPrinter(completion: { completed in
                    completion(completed)
                })
            }
        }
    }

    private func connectToPrinter( completion: (Bool) -> Void) {
        printerConnection = MfiBtPrinterConnection(serialNumber: serialNumber)
        printerConnection?.open()
        completion(true)
    }

    func closeConnectionToPrinter() {
        printerConnection?.close()
    }

    func printBarcode(for content: String) {
        let partName = "Test Part 1"
        let barcodeContent = "4121001245256325233542"
        let partNumber = "41210"
        let partShortName = "TP1"
        let location = "LOC: thisPlace"
        let min = "MIN:-6"
        let max = "MAX: 100"
        if let data = printLabel(with: partName, barcodeContent: barcodeContent, partNumber: partNumber, partShortName: partShortName, location: location, min: min, max: max).data(using: .utf8) {
            writeToPrinter(with: data)
        }
    }

    private func printLabel(with partName: String, barcodeContent: String, partNumber: String, partShortName: String, location: String, min: String, max: String ) -> String {
        let firstText = printerTextField(font: 4, size: 0 , x: 30, y: 0, content: partName)
        let secondText = printerTextField(font: 7, size: 0, x:50 , y:100 , content: "\(partNumber)     \(partShortName)")
        let thirdText = printerTextField(font: 7, size:  0, x: 50, y: 130, content: "\(location)     \(min)     \(max)")
        let barcode = printerBarCodeFormat(width: 2, ratio: 1, height: 50, x: 30, y: 50, content: barcodeContent)
        return "\(CommonPrintingFormat.start.rawValue) \n\(firstText) \n\(barcode) \n\(secondText) \n\(thirdText)\(CommonPrintingFormat.end.rawValue)"
    }

    private func printerTextField(font:Int, size: Int, x:Int, y: Int, content: String) -> String {
        return "TEXT \(font) \(size) \(x) \(y) \(content)"
    }

    private func printMultiLineTextField(linesHeight: Int, font:Int, size: Int, x:Int, y: Int, content: String) -> String {
        return "ML \(linesHeight)\nTEXT \(font) \(size) \(x) \(y) \n\(content)\nENDML\nENDML"
    }

    private func printerBarCodeFormat(width: Int, ratio: Int, height: Int, x: Int, y:Int, content: String) -> String {
        return "BARCODE 128 \(width) \(ratio) \(height) \(x) \(y) \(content)"
    }

    private func writeToPrinter(with data: Data) {
        print(String(data: data, encoding: String.Encoding.utf8) as String!)
        connectToPrinter(completion: { _ in
            var error:NSError?
            printerConnection?.write(data, error: &error)
            if error != nil {
                print("Error executing data writing \(String(describing: error))")
            }

        })
    }

    private func didDisconnect(notification: Notification) {
        isConnected = false
        connectionDelegate?.changeLabelStatus()
    }

    private func didConnect(notification: Notification) {
        isConnected = true
        connectionDelegate?.changeLabelStatus()
    }

}
