
import Foundation
import AwpLocationEngine


open class SyncConfigData{
    
    let mainViewController: ViewController

    let environment : String
    var token : String
    
    var BeaconConfigURL = ""
    var beaconConfigList = [BeaconConfig]()
    
    var FloorConfigURL = ""
    var floorConfigList = [FloorConfig]()
    
    var RegionConfigURL = ""
    var regionConfigList = [RegionConfig]()
    
    var RoomConfigURL = ""
    var roomConfigList = [RoomConfig]()
    
    var AlgorithmConfigURL = ""
    var algorithmConfigList = [AlgorithmConfig]()
    
    var bearerToken: String = ""

    

    init(viewController: ViewController, environment: String, token: String){
        self.mainViewController = viewController

        self.environment = environment
        self.token = token
        
        
        self.BeaconConfigURL = "\(environment)api/ble/beacons"
        self.FloorConfigURL = "\(environment)api/ble/floors"
        self.RegionConfigURL = "\(environment)api/ble/areas"
        self.RoomConfigURL = "\(environment)api/ble/rooms"
        self.AlgorithmConfigURL =  "\(environment)api/ble/algorithmConfig"
        
        self.bearerToken = "Bearer " + token
        
       
    }
    
    
    
    
    internal func createRequestURL(_ url: String) -> NSMutableURLRequest{
        
        let url = URL(string: url)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        request.addValue("application/hal+json", forHTTPHeaderField: "Accept")
        
        
        return request
    }
    
    
    internal func SyncBeaconConfigGetRequest() -> Void {
        
        DispatchQueue.main.async{
            self.mainViewController.txtBeaconConfigCount.text =  "---"
        }
        
        let request = createRequestURL(BeaconConfigURL)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil{
                print(error ?? "error SyncBeaconConfig")
                return
            }
            
            do{
                
                if let jsonOutput = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                    
                   let beaconDict = jsonOutput.allValues as! [[String: AnyObject]]
                    
                    if beaconDict.count > 0{
                    
                        let _embedded = beaconDict[0]
                        
                        if _embedded.count > 0{
                            if let beaconsJson = _embedded["beacons"]{
                                
                                for singleBeacon in beaconsJson as! [[String: AnyObject]]{
                                    
                                    let pid = singleBeacon["id"] as? String
                                    
                                    let regionId = singleBeacon["areaId"] as? Int
                                    let pairedPid = singleBeacon["pairedPid"] as? Double
                                    let longitude = singleBeacon["longitude"] as? Double
                                    let latitude = singleBeacon["latitude"] as? Double
                                    let floorId = singleBeacon["floorId"] as? Int
                                    let x = singleBeacon["x"] as? Double
                                    let y = singleBeacon["y"] as? Double
                                    var placed = singleBeacon["placed"] as? Int
                                    
                                    let interval = singleBeacon["interval"] as? Int
                                    let power = singleBeacon["power"] as? Int
                                    
                                    let typeId = singleBeacon["type"] as? Int
                                    let zoneId = singleBeacon["zone"] as? Int
                                    
                                    let beaconType = BeaconType(rawValue: typeId!)
                                    let beaconZone = BeaconZone(rawValue: zoneId!)
                                    
                                    if placed == nil{
                                        placed = 1
                                    }
                                    
                                    let beaconPlaced = self.convertIntToBool(placed!)
                                    
                                    let beaconConfig = BeaconConfig(id: Int(pid!)!, beaconType: beaconType! , beaconZone: beaconZone!, beaconPower: power!, beaconInterval: interval!, coordinateXY: (x!,y!), coordinateLatLong: (latitude!,longitude!) , regionId: regionId!, floorId: floorId!, pairedId: Int(pairedPid!), placed:  beaconPlaced)
                                    
                                    self.beaconConfigList.append(beaconConfig)
                                    
                                }

                                
                            }

                        }

                    }

                }
                

                DispatchQueue.main.async{
                    self.mainViewController.txtBeaconConfigCount.text =  String(self.beaconConfigList.count)
                }
                       
                
            }catch let error as NSError{
                print(error.localizedDescription)
            }
            
        })
        
        
        task.resume()
        
        
    }

    
    
    
    
    
    
    internal func SyncFloorConfigGetRequest() -> Void {
        
        DispatchQueue.main.async{
            self.mainViewController.txtFloorsConfigCount.text =  "---"
        }
        
        let request = createRequestURL(FloorConfigURL)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil{
                print(error ?? "error SyncFloorConfigGetRequest")
                return
            }
            
            do{
                if let jsonOutput = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                    
                    let floorsDict = jsonOutput.allValues as! [[String: AnyObject]]
                    
                    if floorsDict.count > 0{
                        
                        let _embedded = floorsDict[0]
                        
                        if _embedded.count > 0{
                            if let floorsJson = _embedded["floors"]{
                                
                                for singleFloor in floorsJson as! [[String: AnyObject]]{
                                    
                                    let id = singleFloor["id"] as? Int
                                    let scale = singleFloor["scale"] as? Double
                                    let latitude = singleFloor["latitude"] as? Double
                                    let longitude = singleFloor["longitude"] as? Double
                                    let x = singleFloor["x"] as? Double
                                    let y = singleFloor["y"] as? Double
                                    let rotationAngle = singleFloor["angle"] as? Double
                                    
                                    let floorConfig = FloorConfig(id : id!, scale: scale! , lat: latitude!, longitude: longitude!, latOffset: x!, longOffset: y!, rotAngle: rotationAngle!)
                                    
                                    self.floorConfigList.append(floorConfig)
                                
                                    
                                }
                                
                                
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async{
                    self.mainViewController.txtFloorsConfigCount.text =  String(self.floorConfigList.count)
                }
                
                
            }catch let error as NSError{
                print(error.localizedDescription)
            }
            
        })
        
        
        task.resume()
        
      
    }
    
    
    
    
    internal func SyncRegionConfigGetRequest() -> Void {
        DispatchQueue.main.async{
            self.mainViewController.txtRegionsConfigCount.text =  "---"
        }
        
        
        let request = createRequestURL(RegionConfigURL)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil{
                print(error ?? "error SyncRegionConfigGetRequest")
                return
            }
            
            do{
                if let jsonOutput = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                    
                    let regionDict = jsonOutput.allValues as! [[String: AnyObject]]
                    
                    if regionDict.count > 0{
                        
                        let _embedded = regionDict[0]
                        
                        if _embedded.count > 0{
                            if let areasJson = _embedded["bleAreas"]{
                                
                                for singleRegion in areasJson as! [[String: AnyObject]]{
                                    
                                    let id = singleRegion["id"] as? Int
                                    let parentId = singleRegion["parentId"] as? Int
                                    let regionTypeName = singleRegion["type"] as? String
                                    let regionName = singleRegion["name"] as? String
                                    
                                    let regionType = RegionType(rawValue: regionTypeName!)
                                    
                                    var areaPointsList = [(Double,Double)]()
                                    
                                    if let areaPointsJson = singleRegion["areaPoints"] as? NSArray {
                                        
                                        for areaPointDic in areaPointsJson as! [[String: AnyObject]]{
                                            
                                            let x = areaPointDic["x"] as? Double
                                            let y = areaPointDic["y"] as? Double
                                            
                                            areaPointsList.append(( x!, y!))
                                            
                                        }
                                    }
                                    
                                    
                                    let regionConfig = RegionConfig(id: id!, regionType: regionType!, parentId: parentId!, regionName: regionName!, vertices: areaPointsList )
                                    
                                    self.regionConfigList.append(regionConfig)
                                    
                                }
                                
                                
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async{
                    self.mainViewController.txtRegionsConfigCount.text =  String(self.regionConfigList.count)
                }
                
                
            }catch let error as NSError{
                print(error.localizedDescription)
            }
            
        })
        
        
        task.resume()

        
    }

    
    
    
    
    
    
    internal func SyncRoomConfigGetRequest() -> Void {
        DispatchQueue.main.async{
            self.mainViewController.txtRoomsConfigCount.text =  "---"
        }
        
        
        let request = createRequestURL(RoomConfigURL)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil{
                print(error ?? "error SyncRoomConfigGetRequest")
                return
            }
            
            do{
                if let jsonOutput = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                    
                    let roomsDict = jsonOutput.allValues as! [[String: AnyObject]]
                    
                    if roomsDict.count > 0{
                        
                        let _embedded = roomsDict[0]
                        
                        if _embedded.count > 0{
                            if let roomsJson = _embedded["rooms"]{
                                
                                for singleRoom in roomsJson as! [[String: AnyObject]]{
                                    
                                    let id = singleRoom["id"] as? Int
                                    let categoryName = singleRoom["category"] as? String
                                    var hallwayId = singleRoom["hallway"] as? Int
                                    
                                    let roomCategory = self.getRoomCategoryFromString(categoryName!)
                                    
                                    var firstOrderRooms = [Int]()
                                    
                                    
                                    if let firstOrder = singleRoom["firstOrderRooms"] as? NSArray {
                                        
                                        for roomId  in firstOrder{
                                            firstOrderRooms.append((roomId as? Int)!)
                                        }
                                    }
                                                       
                                    if hallwayId == nil{
                                        hallwayId = 0
                                    }
                                    if roomCategory != nil{
                                        let roomConfig = RoomConfig(id: id!, category: roomCategory!, hallwayId: hallwayId!, firstOrderRooms: firstOrderRooms )
                                    
                                        self.roomConfigList.append(roomConfig)
                                        
                                    }
                                    
                                }
                                
                                
                            }
                        }
                    }
                }
                
                
                DispatchQueue.main.async{
                    self.mainViewController.txtRoomsConfigCount.text =  String(self.roomConfigList.count)
                }
                
                
            }catch let error as NSError{
                print(error.localizedDescription)
            }
            
        })
        
        
        task.resume()
        
 
        
    }


    
    
    internal func SyncAlgorithmConfigGetRequest() -> Void {
        
        DispatchQueue.main.async{
            self.mainViewController.txtAlgorithmsConfigCount.text =  "---"
        }
        
        
        
        let request = createRequestURL(AlgorithmConfigURL)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil{
                print(error ??  "error SyncAlgorithmConfigGetRequest")
                return
            }
            
            do{
                if let jsonOutput = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                    
                    let algorithmDict = jsonOutput.allValues as! [[String: AnyObject]]
                    
                    if algorithmDict.count > 0{
                        
                        let _embedded = algorithmDict[0]
                        
                        if _embedded.count > 0{
                            if let algorithmJson = _embedded["items"]{
                                
                                for singleAlgorithm in algorithmJson as! [[String: AnyObject]]{
                                    
                                    if singleAlgorithm["configType"] as? String == "SITE_DEFAULT"{
                                        
                                    
                                        let platform = singleAlgorithm["platform"] as! [String: AnyObject]
                                    
                                        if  platform["name"] as? String == "iOS"{
                                        
                                            if let configValuesJson = singleAlgorithm["configValues"] as? NSArray {
                                            
                                                for configValue in configValuesJson as! [[String: AnyObject]]{
                                                
                                                    let value = configValue["value"]! as AnyObject
                                                    let keyJson = configValue["key"]! as AnyObject
                                                    let keyName = keyJson["name"] as? String
                                                
                                                    var keyValue = String(describing: value)
                                                                                        
                                                    let algorithmConfig = AlgorithmConfig(keyName: keyName!, keyValue: keyValue )
                                                
                                                    self.algorithmConfigList.append(algorithmConfig)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                       }
                }
                
                
                    DispatchQueue.main.async{
                        self.mainViewController.txtAlgorithmsConfigCount.text =  String(self.algorithmConfigList.count)
                    }
               
            }
        }catch{
                    print("SyncAlgorithConfigGetRequest Error: \(error)")
        }
            
    })
        
        
    task.resume()
        
 }
    
    
    internal func convertIntToBool( _ input: Int) -> Bool{
    
        if input == 1{
            return true
        }else if input == 0{
            return false
        }
    
        
        return false
    
    }
    
    
    func getRoomCategoryFromString(_ name: String)->RoomCategory?{
        var initial = 0
        
        while let roomCategory = RoomCategory(rawValue: initial){
            if String(describing: roomCategory) == name{
                return roomCategory
            }
            initial += 1
        }
        
        return nil
        
    }
    
}
