//
//  ViewController.swift
//  ios-ble-demo
//
//  Created by Eiji Kushida on 2017/05/24.
//  Copyright © 2017年 Eiji Kushida. All rights reserved.
//

import UIKit

//Central : 本アプリ
//Peripheral : Light Blue
final class ViewController: UIViewController {

    //GATTサービス(Heart Rate) https://www.bluetooth.com/ja-jp/specifications/gatt/services
    let kServiveUUIDHeartRate = "0x180D"

    //Attribute Types (UUIDs)
    let kCharacteristcUUIDHeartRateMeasurement = "0x2A37"

    let bleHelper = BLEHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        bleHelper.setup(serviveUUIDHeartRate: kCharacteristcUUIDHeartRateMeasurement,
                        characteristcUUIDHeartRateMeasurement: kCharacteristcUUIDHeartRateMeasurement)
    }
}

//MARK : - BLEDelegate
extension ViewController: BLEDelegate {

    func completion(state: BLEState) {

        switch state {
        case .success(let data):
            updateWithData(data: data)

        case .failure(let messsage):
            fatalError(messsage)
        }
    }

    private func updateWithData(data : Data) {

        let reportData = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
        }

        if (reportData.first != nil) && 0x01 == 0 {
            print("BPM1: \(reportData.last!)")
        } else {
            print("BPM2 : \(CFSwapInt16LittleToHost(UInt16(reportData.last!)))")
        }
    }
}
