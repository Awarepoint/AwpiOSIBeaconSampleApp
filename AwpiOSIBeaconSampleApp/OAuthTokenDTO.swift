import Foundation

public struct OAuthTokenDTO {
    let environment: String
    let accessToken: String
    let tokenType: String
    let expiresInSeconds: Int
    let expiryDate: Date
    let refreshToken: String
    
    
    init(environment: String, accessToken: String, tokenType: String, expiresInSeconds: Int, expiryDate: Date, refreshToken: String){
        self.environment = environment
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresInSeconds = expiresInSeconds
        self.expiryDate = expiryDate
        self.refreshToken = refreshToken
        
    }
    
}
