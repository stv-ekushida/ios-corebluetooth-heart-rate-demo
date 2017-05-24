//
//  ViewController.swift
//  ios-ble-demo
//
//  Created by Eiji Kushida on 2017/05/24.
//  Copyright © 2017年 Eiji Kushida. All rights reserved.
//

import UIKit
import CoreBluetooth

//Central : 本アプリ
//Peripheral : Light Blue
final class ViewController: UIViewController {

    //GATTサービス(Heart Rate) https://www.bluetooth.com/ja-jp/specifications/gatt/services
    let kServiveUUIDHeartRate = "0x180D"

    //Attribute Types (UUIDs)
    let kCharacteristcUUIDHeartRateMeasurement = "0x2A37"

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID : CBUUID!
    var charcteristicUUID: CBUUID!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    /// セントラルマネージャー、UUIDの初期化
    private func setup() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        serviceUUID = CBUUID(string: kServiveUUIDHeartRate)
        charcteristicUUID = CBUUID(string: kCharacteristcUUIDHeartRateMeasurement)
    }
}

//MARK : - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(#function)

        switch central.state {

        //電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            let services: [CBUUID] = [serviceUUID]
            centralManager?.scanForPeripherals(withServices: services,
                                               options: nil)
        default:
            break
        }
    }

    /// ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        print(#function)

        self.peripheral = peripheral
        centralManager?.stopScan()

        //接続開始
        central.connect(peripheral, options: nil)
    }

    /// 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print(#function)

        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
}

//MARK : - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {

    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        print(#function)

        if error != nil {
            print(error.debugDescription)
            return
        }

        //キャリアクタリスティク探索開始
        peripheral.discoverCharacteristics([charcteristicUUID],
                                           for: (peripheral.services?.first)!)
    }

    /// キャリアクタリスティク発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        print(#function)

        if error != nil {
            print(error.debugDescription)
            return
        }

        peripheral.setNotifyValue(true,
                                  for: (service.characteristics?.first)!)
    }

    /// データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print(#function)

        if error != nil {
            print(error.debugDescription)
            return
        }

        updateWithData(data: characteristic.value!)
    }

    private func updateWithData(data : Data) {
        print(#function)

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

