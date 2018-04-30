import UIKit
import CoreBluetooth

/**
 A class that interfaces with AwareHealth API to retrieve configuration (beacon, region, floor, room) necessary to initialize the location engine
 Note that the AwareHealth API uses oauth 2.0, client-credential grant type, to protect its resources.
 */
class RestClient {
    
    var SYSMAN_AUTH_URL = "https://oauthservice-sdble.qa3.awarepoint.com/oauth/token"
    let OAUTH_CLIENT_ID = "awarepoint"
    let OAUTH_CLIENT_SECRET = "middleout"
    var OAUTH_USERNAME = "staffmobility"
    var OAUTH_PASSWORD = "staffmobility"
    let OAUTH_GRANT_TYPE = "client_credentials"// "password"
    
    
    var oAuthTokenDTO: OAuthTokenDTO? = nil
    
       
    /**
     Obtains a OAuth 2.0 access token
     */
    func postOAuthRequest(_ scopeKey: String) -> OAuthTokenDTO? {
        
        let body = "client_id="+OAUTH_USERNAME+"&client_secret="+OAUTH_PASSWORD+"&scope=apikey%3D"+scopeKey+"&grant_type="+OAUTH_GRANT_TYPE

        if let jsonResult = httpPostRequestJsonResponse(SYSMAN_AUTH_URL, bodyAsString: body){
            
            
            if jsonResult["error"] != nil{
                return nil
            }else{
            
                let calendar = Calendar.current
                let expiryDate = (calendar as NSCalendar).date(byAdding: .second,  value: jsonResult["expires_in"]! as! Int, to: Date(), options: [])!
            
            
                oAuthTokenDTO = OAuthTokenDTO(environment: SYSMAN_AUTH_URL, accessToken: jsonResult["access_token"]! as! String,  tokenType: jsonResult["token_type"]! as! String, expiresInSeconds: jsonResult["expires_in"]! as! Int
                , expiryDate: expiryDate, refreshToken: jsonResult["refresh_token"]! as! String)
                
                return oAuthTokenDTO
            }
        }
        return nil
    }
   
    internal func httpPostRequestJsonResponse(_ urlPath:String, bodyAsString: String) -> NSDictionary?  {
        let url: URL = URL(string: urlPath)!
        let body = (bodyAsString as NSString).data(using: String.Encoding.utf8.rawValue)
        
        // Define the request
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        return httpRequestJsonResponse(request)
    }
    
    

    internal func httpGetRequestJsonResponse(_ urlPath:String, headers:[String: String]) -> NSDictionary?  {
        let url: URL = URL(string: urlPath)!
        
        // Define the request
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add request headers
        for (aHeader, aValue) in headers {
           print("Addin header  \(aHeader) value \(aValue)")
           // request.addValue(aValue, forHTTPHeaderField: aHeader)
        }
        
        if headers.count > 0{
            request.allHTTPHeaderFields = headers
        }
        
        return httpRequestJsonResponse(request)
    }
    
    
    
    
    fileprivate func httpRequestJsonResponse(_ request:NSMutableURLRequest) -> NSDictionary?  {
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>?=nil
        do {
            
            //TODO fix deprecation of sendSynchronousRequest
            let dataVal = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: response)
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: dataVal, options:[] ) as? NSDictionary {
                    //print("Synchronous\(jsonResult)")
                    //for (aName, aValue) in jsonResult {
                    //    print("Dictionary Entry name \(aName) value \(aValue)")
                    // }
                    return jsonResult
                }
            } catch let error as NSError {
                print("(Inner do) Contents of NSError:")
                print(error.localizedDescription)
            }
            
            
        } catch let error as NSError
        {
            print("(Outer do) Contents of NSError:")
            print(error.localizedDescription)
        }
        return nil
    }
    

    
   
    
}
