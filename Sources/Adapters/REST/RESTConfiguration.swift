//
//  RESTConfiguration.swift
//  Arcade
//
//  Created by Paul Foster on 11/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct RESTConfiguration {
    
    public var apiScheme: String
    public var apiHost: String
    public var apiPort: Int
    public var apiPath: String?
    
    public var session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    public init(apiScheme: String, apiHost: String, apiPort: Int = 80, apiPath: String?) {
        self.apiScheme = apiScheme
        self.apiHost = apiHost
        self.apiPort = apiPort
        self.apiPath = apiPath
    }
    
}
