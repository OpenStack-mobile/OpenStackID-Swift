//
//  ClientCredentialsGrant.swift
//  OpenStackID
//
//  Created by Alsey Coleman Miller on 12/19/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import SwiftFoundation

public struct ClientCredentialsGrant {
    
    public struct Request: AccessTokenRequest {
        
        public enum Parameter: String {
            
            case grant_type, scope, client_id, client_secret
        }
        
        public static let grantType: AccessTokenGrantType = .clientCredentials
        
        /// The URL of the OAuth2 endpoint for access token grants.
        public var endpoint: URL
        
        public var scope: String?
        
        public var credentials: (clientIdentifier: String, clientSecret: String)?
        
        public func toURLRequest() -> HTTP.Request {
            
            var parameters = [Parameter: String]()
            
            parameters[.grant_type] = type(of: self).grantType.rawValue
            
            parameters[.scope] = scope
            
            if let (clientID, clientSecret) = credentials {
                
                parameters[.client_id] = clientID
                
                parameters[.client_secret] = clientSecret
            }
            
            // crashes compiler
            //let stringParameters = parameters.reduce([String: String](), { $0.0[$0.1.key.rawValue] = $0.1.value })
            
            var stringParameters = [String: String](minimumCapacity: parameters.count)
            parameters.forEach { stringParameters[$0.0.rawValue] = $0.value }
            
            let formURLEncoded = FormURLEncoded(parameters: stringParameters)
            
            return HTTP.Request(url: endpoint,
                                body: formURLEncoded.toData(),
                                headers: ["Content-Type": "application/x-www-form-urlencoded"])
        }
    }
    
    /// [5.1.  Successful Response](https://tools.ietf.org/html/rfc6749#section-5.1)
    ///
    /// The authorization server issues an access token and optional refresh token, and constructs the response.
    ///
    /// For example:
    /// ```
    /// HTTP/1.1 200 OK
    /// Content-Type: application/json;charset=UTF-8
    /// Cache-Control: no-store
    /// Pragma: no-cache
    ///
    /// {
    /// "access_token":"2YotnFZFEjr1zCsicMWpAA",
    /// "token_type":"example",
    /// "expires_in":3600,
    /// "refresh_token":"tGzv3JOkF0XG5Qx2TlKWIA",
    /// "example_parameter":"example_value"
    /// }
    /// ```
    public struct Response: AccessTokenResponse, JSONDecodable {
        
        public static let grantType: AccessTokenGrantType = .clientCredentials
        
        public let accessToken: String
        
        public let tokenType: String
        
        public let expires: TimeInterval?
        
        public init?(urlResponse: HTTP.Response) {
            
            guard urlResponse.statusCode == HTTP.StatusCode.OK.rawValue,
                let jsonString = String(UTF8Data: urlResponse.body),
                let json = JSON.Value(string: jsonString)
                else { return nil }
            
            self.init(JSONValue: json)
        }
        
        public init?(JSONValue: JSON.Value) {
            
            guard let JSONObject = JSONValue.objectValue,
                let accessToken = JSONObject[AccessTokenResponseParameter.access_token.rawValue]?.stringValue,
                let tokenType = JSONObject[AccessTokenResponseParameter.token_type.rawValue]?.stringValue
                else { return nil }
            
            self.accessToken = accessToken
            self.tokenType = tokenType
            
            if let expires = JSONObject[AccessTokenResponseParameter.expires_in.rawValue]?.integerValue {
                
                self.expires = TimeInterval(expires)
                
            } else {
                
                self.expires = nil
            }
        }
    }
}
