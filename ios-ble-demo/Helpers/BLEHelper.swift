//
//  BLEHelper.swift
//  ios-ble-demo
//
//  Created by Eiji Kushida on 2017/05/25.
//  Copyright © 2017年 Eiji Kushida. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BLEState {
    case success(data: Data)
    case failure(message: String)
}

protocol BLEDelegate: class {
    func completion(state: BLEState)
}

final class BLEHelper: NSObject {

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID : CBUUID!
    var charcteristicUUID: CBUUID!

    weak var delegate: BLEDelegate?

    /// セントラルマネージャー、UUIDの初期化
    func setup(serviveUUIDHeartRate: String,
               characteristcUUIDHeartRateMeasurement: String) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        serviceUUID = CBUUID(string: serviveUUIDHeartRate)
        charcteristicUUID = CBUUID(string: characteristcUUIDHeartRateMeasurement)
    }
}

//MARK : - CBCentralManagerDelegate
extension BLEHelper: CBCentralManagerDelegate {

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
extension BLEHelper: CBPeripheralDelegate {

    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        print(#function)

        if let error = error {
            delegate?.completion(state: .failure(message: (error.localizedDescription)))
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

        if let error = error {
            delegate?.completion(state: .failure(message: (error.localizedDescription)))
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

        if let error = error {
            delegate?.completion(state: .failure(message: (error.localizedDescription)))
            return
        }

        delegate?.completion(state: .success(data: characteristic.value!))
    }
}
