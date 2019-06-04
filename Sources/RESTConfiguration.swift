//
//  RESTConfiguration.swift
//  Arcade
//
//  Created by Paul Foster on 11/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct RESTConfiguration {
    
    public var session: URLSession?
    
    public var apiKey: String?
    public var apiScheme: String
    public var apiHost: String
    public var apiPort: Int?
    public var apiPath: String?
    
    public init(apiKey: String?, apiScheme: String, apiHost: String, apiPort: Int?, apiPath: String?, session: URLSession = URLSession(configuration: URLSessionConfiguration.default)) {
        self.apiKey = apiKey
        self.apiScheme = apiScheme
        self.apiHost = apiHost
        self.apiPort = apiPort
        self.apiPath = apiPath
        
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }
    
}
