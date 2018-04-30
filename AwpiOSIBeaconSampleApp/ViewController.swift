import UIKit
import CoreBluetooth
import CoreMotion
import CoreLocation
import AwpLocationEngine

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, CBCentralManagerDelegate, CLLocationManagerDelegate {
    
    let logger = LoggerLocationEngine()
    
    var configManager : ConfigManager? = nil
    var mobileInputCore : MobileInputCore? = nil
    var motionManager : CMMotionManager? = nil
    
    
    //IBeacon
    var isRunningInBackground = false
    var isScanningForIBeacons = false
    var bleIBeaconAvailable = false
    
    var locationManager: CLLocationManager?
    var awpProximityUUID: UUID?
    var awpRegion: CLBeaconRegion?

    var syncConfigData: SyncConfigData? = nil
    
    
    let locationChangeListener = LocationChangeListener()
    
    @IBOutlet weak var btnSendDataLE: UIButton!
    
    var bleScanAvailable = false
    
    var centralManager: CBCentralManager?

    var restClient = RestClient()
    var token: String? = nil
    var environmentSelected: String? = nil
    
    var beaconsListening = [(String, Double)]()
    var outputListening = [String]()
    
    var accelerometerX: Double = 0
    var accelerometerY: Double = 0
    var accelerometerZ: Double = 0
    
    
    @IBOutlet weak var pickerAppliances: UIPickerView!
    
    var awareHealthURL = ["https://awareHealthAPI.qa3.awarepoint.com/"]
    
    
    @IBOutlet weak var txtOutput: UITextView!
    @IBOutlet weak var txtBeacons: UITextView!
    
    @IBOutlet weak var txtScopeKey: UITextField!
    
    @IBOutlet weak var btnScan: UIButton!
    
    @IBOutlet weak var lblToken: UILabel!
    
    @IBOutlet weak var txtBeaconConfigCount: UITextField!
    @IBOutlet weak var txtRegionsConfigCount: UITextField!
    @IBOutlet weak var txtRoomsConfigCount: UITextField!
    @IBOutlet weak var txtFloorsConfigCount: UITextField!
    @IBOutlet weak var txtAlgorithmsConfigCount: UITextField!
    
    let bluetoothQueue = DispatchQueue(label: "ble_devices_queue", attributes: [])
    
    var currentTime = Int64( Date().timeIntervalSince1970 * 1000 )
    
    @IBAction func btnStartScan(_ sender: AnyObject) {
        
        
       if syncConfigData != nil{
            
            if bleScanAvailable {
        
                if btnScan.titleLabel?.text == "Start Scan"{
                    startScanning()
                    self.startScanningIBeacons()
                    
                    btnScan.setTitle("Stop Scan", for: UIControlState())
                
                }else{
                    stopScanning()
                    self.stopScanningIBeacons()
                    
                    btnScan.setTitle("Start Scan", for: UIControlState())
                
                }
            }
        }else{
            print("Data is not loaded to location engine")
        }

    
    }
    
    
    
    @IBAction func btnRequestToken(_ sender: UIButton) {
        
        let scopeKey = txtScopeKey.text

        if let oAuthTokenDTO =  restClient.postOAuthRequest(scopeKey!){
            token = oAuthTokenDTO.accessToken
            
            lblToken.text = token
            
        }else{
            lblToken.text = "Error Getting the token"
        }

    }
    
    
    @IBAction func btnSyncSite(_ sender: AnyObject) {

        DispatchQueue.main.async {
            self.btnScan.isEnabled = false
            self.btnSendDataLE.isEnabled = false
        }
        
        
        if(environmentSelected == nil){
            environmentSelected = awareHealthURL[0]
        }
        
        syncConfigData = SyncConfigData(viewController: self, environment: environmentSelected!, token: token!)
        
        syncConfigData!.SyncBeaconConfigGetRequest()
        syncConfigData!.SyncFloorConfigGetRequest()
        syncConfigData!.SyncRegionConfigGetRequest()
        syncConfigData!.SyncRoomConfigGetRequest()
        syncConfigData!.SyncAlgorithmConfigGetRequest()

        DispatchQueue.main.async {
            self.btnScan.isEnabled = true
            self.btnSendDataLE.isEnabled = true
        }

    }
    
    
    @IBAction func btnSendDataLE(_ sender: UIButton) {
        
        if syncConfigData != nil{
            
            if bleScanAvailable {
          
                if syncConfigData!.beaconConfigList.count > 0 && syncConfigData!.floorConfigList.count > 0 && syncConfigData!.regionConfigList.count > 0 && syncConfigData!.roomConfigList.count > 0{

                    configManager = ConfigManager (beaconConfigsInput: syncConfigData!.beaconConfigList, regionConfigsInput: syncConfigData!.regionConfigList, floorConfigsInput: syncConfigData!.floorConfigList, roomConfigsInput: syncConfigData!.roomConfigList, algorithmConfigsInput: syncConfigData!.algorithmConfigList)
                    
                    
                    mobileInputCore = MobileInputCore(configManager: configManager!, locationChangeListener : locationChangeListener )
                 
                
                }else{
                    print("Data is not complete")
                }
            }else{
                print("BLE Scan not Available")
            }
        }
        
        
    }

    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerAppliances.dataSource = self
        self.pickerAppliances.delegate = self
        
        
        centralManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
        
        locationChangeListener.notificationCenter.addObserver(self, selector: #selector(ViewController.notifyLocationOutputChange),   name: NSNotification.Name(rawValue: locationChangeListener.notificationCenterName), object: nil)
        locationChangeListener.notificationCenter.addObserver(self, selector: #selector(goingBackground),  name: NSNotification.Name.UIApplicationDidEnterBackground  , object: nil)
        locationChangeListener.notificationCenter.addObserver(self, selector: #selector(goingForeground),  name: NSNotification.Name.UIApplicationDidBecomeActive  , object: nil)
        
        
        self.motionManager = CMMotionManager()
        self.motionManager!.startAccelerometerUpdates()
        
        //IBeacons
        awpProximityUUID = UUID(uuidString: "f56d9233-9adf-48e2-902d-34a544dd1b82")
        awpRegion = CLBeaconRegion(proximityUUID: awpProximityUUID!, identifier: "Awarepoint")
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.requestAlwaysAuthorization()
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.allowsBackgroundLocationUpdates = true
        locationManager!.pausesLocationUpdatesAutomatically = false
        
    }
    
    
    deinit{
        centralManager!.stopScan()
    }
    
    
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.tag == 1{
            return awareHealthURL.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 1{
            environmentSelected = awareHealthURL[row]
        }
        
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.tag == 1{
           return awareHealthURL[row]
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerLabel = view as? UILabel
        
        if pickerLabel == nil{
            pickerLabel = UILabel()
        }
        
        pickerLabel?.textColor = UIColor.red
        pickerLabel?.font = UIFont( name: "Arial", size: 16)
        pickerLabel?.textAlignment = NSTextAlignment.center
        
        if pickerView.tag == 1{
            pickerLabel?.text = awareHealthURL[row]
        }
        
        
        return pickerLabel!
        
    }

    
    // BLE Scanning
    

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            print("poweredOff")
            bleScanAvailable = false
        case .poweredOn:
            print("poweredOn!")
            bleScanAvailable = true
        default:
            print(central.state)
        }
        
        
    }
    
    
    var beaconCount = 0
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // FIX ME - Temp Solution After a few seconds scan slow down and takes more time to detect devices, restarting the process fix the issue.
        let thisTime = Int64( Date().timeIntervalSince1970 * 1000 )
        
        if (thisTime - currentTime) > 10000{
            restartScanning()
            currentTime = thisTime
        }
        
        if mobileInputCore != nil{
            
            let beaconPid = decryptPid(advertisementData as [String : AnyObject])
            let timestamp = Int64( Date().timeIntervalSince1970 * 1000 )
            
            if beaconPid != 0 && Double(RSSI) < 0 {
                
                accelerometerX = 0
                accelerometerY = 0
                accelerometerZ = 0

                if let accelerometerData = motionManager!.accelerometerData{
                    accelerometerX = accelerometerData.acceleration.x
                    accelerometerY = accelerometerData.acceleration.y
                    accelerometerZ = accelerometerData.acceleration.z
                }
                
                let beaconString = String(beaconPid, radix: 16).uppercased()
                
                
                if configManager != nil{
                    
                    if configManager!.beaconsConfig[beaconPid] != nil{
                        
                        mobileInputCore!.publish(0, beaconPid: beaconPid, rssi: Double(RSSI), timestamp: timestamp, inMotion: true, accelerometerX: accelerometerX, accelerometerY: accelerometerY, accelerometerZ: accelerometerZ)

                        DispatchQueue.main.async(execute: {
                            self.txtBeacons.text = self.txtBeacons.text + " " + beaconString + " : " + String(describing: RSSI) + "\r\n";
                    
                            self.beaconsListening.append((beaconString, Double(RSSI)) )
                        
                            if self.beaconsListening.count > 20{
                                self.beaconsListening.removeAll()
                                self.txtBeacons.text = ""
                            }
                        })
                        
                    }
                    
                }
             
            }
        }
        
    }
    
    
    
    
    func decryptPid(_ advertisementData: [String : AnyObject])-> Int{
        var beaconPid : Int = 0
  
        let manufacturerData = advertisementData["kCBAdvDataManufacturerData"]
        if (manufacturerData != nil) {
            let manufacturerDataNsData = manufacturerData as! Data
            if (manufacturerDataNsData.count == 10) { //awarepoint format always 10 bytes
                var tenbytes = [UInt8](repeating: 0, count: 10)
                (manufacturerDataNsData as NSData).getBytes(&tenbytes, length: manufacturerDataNsData.count)
                // awarepoint identifier is 0x3c02
                if (tenbytes[0] == 0x3c && tenbytes[1] == 0x02) {
                    // construct the pid, by adding prepending 0x9000 to 3 bytes from the part of the manufacturer field that encodes the beacon id
                    var bytes : [UInt8] = [0x90,0x00,0x00,0x00,0x00]
                    bytes[2...4] = tenbytes[6...8]
                                        for byte in bytes {
                        beaconPid = beaconPid<<8
                        beaconPid = beaconPid | Int(byte)
                    }
                }
            }
        }

        return beaconPid
        
    }
    
    
    @objc internal func notifyLocationOutputChange(_ notification: Notification){
     
        if let userInfoNotification = notification.userInfo{
        
            if let locationOutputNotification = userInfoNotification["locationOutput"] as? [String:AnyObject]{

                let productId = locationOutputNotification["productId"] as! Int
                let fullLocationName = locationOutputNotification["fullLocationName"] as! String
                let campusId = locationOutputNotification["campusId"] as! Int
                let buildingId = locationOutputNotification["buildingId"] as! Int
                let floorId = locationOutputNotification["floorId"] as! Int
                let areaId = locationOutputNotification["areaId"] as! Int
                let roomId = locationOutputNotification["roomId"] as! Int
                let subroomId = locationOutputNotification["subroomId"] as! Int
                let x = locationOutputNotification["x"] as! Double
                let y = locationOutputNotification["y"] as! Double
                let latitude = locationOutputNotification["latitude"] as! Double
                let longitude = locationOutputNotification["longitude"] as! Double
                let inMotion = locationOutputNotification["inMotion"] as! Bool
                
                let msgReceiveTime = Int64(locationOutputNotification["msgReceiveTime"] as! Int)
                let locationOutputTime = Int64(locationOutputNotification["locationOutputTime"] as! Int)
 
                
                let locationOutput = LocationOutput(productId: productId, msgReceiveTime: msgReceiveTime, locationOutputTime: locationOutputTime, fullLocationName: fullLocationName, campusId: campusId, buildingId: buildingId, floorId: floorId, areaId: areaId, roomId: roomId, subroomId: subroomId, x: x, y: y, latitude: latitude, longitude: longitude, inMotion: inMotion)
                
  
                 DispatchQueue.main.async(execute: {

                    if self.outputListening.count > 2{
                        self.outputListening.removeAll()
                        self.txtOutput.text = ""
                    }
                
                    let output = fullLocationName + " | x:" +  String(x) + " | y:" + String(y) + " | lat:" + String(latitude) + " | long:" + String(longitude)
                    
                    self.txtOutput.text = output + "\r\n ***************\r\n" + self.txtOutput.text

                    
                    
                    
                    self.outputListening.append(fullLocationName)
                })

                
                
            }
        }
        
        
        
    }
    
    
    //Scan Beacons
    internal func startScanning(){
        self.bluetoothQueue.async(execute: { self.centralManager!.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true]) })
    }
    
    
    internal func stopScanning(){
        self.bluetoothQueue.async(execute: { self.centralManager!.stopScan() })
        
    }
    
    internal func restartScanning(){
    
        if self.centralManager!.isScanning{
            stopScanning()
        }
        
        startScanning()
    }
    
    
    
    
    @objc func goingBackground(_ notification: Notification){
        logger.info("App State: goingBackground")
        
        isRunningInBackground = true
        self.restartScanningIBeacons()
    }
    
    @objc func goingForeground(_ notification: Notification){
        logger.info("App State: goingForeground")
        isRunningInBackground = false
        self.restartScanningIBeacons()
    }
    
    
    //IBeacons
    func startScanningIBeacons(){
        if bleScanAvailable{
            locationManager!.startUpdatingLocation()
            //locationManager!.startMonitoring(for: awpRegion!)
            locationManager!.startRangingBeacons(in: awpRegion!)
            
            isScanningForIBeacons = true
        }else{
            //utilities.showMessage(title: "Bluetooth is disabled", message: "Bluetooth must be enable in order to scan for IBeacons, go to setting and enable Bleuetooth")
        }
        
    }
    
    func stopScanningIBeacons(){
        locationManager?.stopUpdatingLocation()
        //locationManager!.stopMonitoring(for: awpRegion!)
        locationManager?.stopRangingBeacons(in: awpRegion!)
        
        isScanningForIBeacons = false
    }
    
    func restartScanningIBeacons(){
        
        if isScanningForIBeacons{
            stopScanningIBeacons()
            startScanningIBeacons()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways{
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
                if CLLocationManager.isRangingAvailable(){
                    bleIBeaconAvailable = true
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion{
            if CLLocationManager.isRangingAvailable(){
                manager.startRangingBeacons(in: region as! CLBeaconRegion)
                
                logger.info("locationManager: ")
                
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        logger.info("************** Pause Location Update")
    }
    
    var numberFound = 0
    var beaconConfigList = [String]()
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0{
            
            for beacon in beacons{
                
                let nearestBeacon = beacon
                let RSSI = Double(nearestBeacon.rssi)
                
                numberFound = numberFound + 1
                if nearestBeacon.proximity == .near || nearestBeacon.proximity == .immediate || nearestBeacon.proximity == .far{
                    
                    
                    if configManager != nil{
                        
                        accelerometerX = 0
                        accelerometerY = 0
                        accelerometerZ = 0
                        
                        if let accelerometerData = motionManager!.accelerometerData{
                            accelerometerX = accelerometerData.acceleration.x
                            accelerometerY = accelerometerData.acceleration.y
                            accelerometerZ = accelerometerData.acceleration.z
                        }
                        
                        let timestamp = Int64( Date().timeIntervalSince1970 * 1000 )
                        // self.logger.info("nearestBeacon: \(nearestBeacon)  ")
                        let beaconAdd1 = String(format:"%2X", nearestBeacon.major.int64Value)
                        let beaconAdd2 = String(format:"%2X", nearestBeacon.minor.int64Value)
                        
                        
                        let beaconPartialPid = "\(beaconAdd1.suffix(2))\(beaconAdd2)"
                        
                        var beaconString = "9000\(beaconPartialPid)"
                        
                        
                        if beaconString.count == 9{
                            beaconString = "90000\(beaconPartialPid)"
                        }
                        
                        
                        let beaconPid = Int(beaconString, radix: 16)
                        
                        
                        if configManager!.beaconsConfig[beaconPid!] != nil{
                            
                            mobileInputCore!.publish(0, beaconPid: beaconPid!, rssi: RSSI, timestamp: timestamp, inMotion: true, accelerometerX: accelerometerX, accelerometerY: accelerometerY, accelerometerZ: accelerometerZ)
                            
                            var status = ""
                            if isRunningInBackground{
                                status = "Ba"
                            }else{
                                status = "Fo"
                            }
                            let beaconMessage =  "\(status) - \(beaconString) : \(String(describing: nearestBeacon.rssi))"
                            
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newIBeacon"), object: beaconMessage)
                            beaconConfigList.append(beaconMessage)
                        }
                    }
                    
                }
                
            }
        }
    }
    
    
}

