//
//  RESTHelper.swift
//  Arcade
//
//  Created by Aaron Wright on 4/23/19.
//  Copyright © 2019 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct RESTHelper {
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    public static func url(configuration: RESTConfiguration, forTable table: Table?, uuid: String?, urlComponents: URLComponents = URLComponents(), options: [QueryOption] = []) -> URL? {
        var urlComponents = urlComponents
        urlComponents.scheme = configuration.apiScheme
        
        if let table = table {
            urlComponents.host = configuration.apiHost
            urlComponents.path = configuration.apiPath != nil ? "/\(configuration.apiPath!)/\(table.name)" : "/\(table.name)"
            urlComponents.port = configuration.apiPort
        }
        
        if let uuid = uuid { urlComponents.path += "/\(uuid)" }
        
        options.forEach {
            if let value = $0.value as? String {
                if urlComponents.queryItems == nil {
                    urlComponents.queryItems = [URLQueryItem(name: $0.key, value: value)]
                } else {
                    urlComponents.queryItems?.append(URLQueryItem(name: $0.key, value: value))
                }
            }
        }
        
        return urlComponents.url
    }
    
    public static func url(configuration: RESTConfiguration, forResource resource: String, uuid: String?, urlComponents: URLComponents = URLComponents(), options: [QueryOption] = []) -> URL? {
        var urlComponents = urlComponents
        urlComponents.scheme = configuration.apiScheme
        urlComponents.host = configuration.apiHost
        urlComponents.path = configuration.apiPath != nil ? "/\(configuration.apiPath!)/\(resource)" : "/\(resource)"
        urlComponents.port = configuration.apiPort
        
        if let uuid = uuid { urlComponents.path += "/\(uuid)" }
        
        options.forEach {
            if let value = $0.value as? String {
                if urlComponents.queryItems == nil {
                    urlComponents.queryItems = [URLQueryItem(name: $0.key, value: value)]
                } else {
                    urlComponents.queryItems?.append(URLQueryItem(name: $0.key, value: value))
                }
            }
        }
        
        return urlComponents.url
    }
    
    public static func urlComponents(forQuery query: Query?, search: String?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) throws -> URLComponents {
        var urlComponents = URLComponents()
        
        urlComponents.queryItems = try RESTQueryBuilder(query: query, search: search, sorts: sorts, limit: limit, offset: offset).queryItems()
        
        return urlComponents
    }
    
    public static func urlRequest(forURL url: URL, method: Method, authorization: RESTAdapter.AdapterAuthorization?, data: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        if let authorization = authorization {
            switch authorization {
            case .token(let token):
                headers["Authorization"] = "Bearer \(token)"
            case .credentials(let username, let password):
                if let auth = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() { headers["Authorization"] = "Basic \(auth)" }
            }
        }
        
        request.allHTTPHeaderFields = headers
        request.httpBody = data
        
        return request
    }
    
    public static func encode<T>(value: T) throws -> Data? where T : Encodable {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try encoder.encode(value)
    }
    
    public static func decode<T>(data: Data) throws -> T where T : Decodable {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
    
    public static func decodeViewable<T>(from data: Data, table: Table) throws -> T where T : Viewable {
        return try self.decode(data: data)
    }
    
    public static func decodeArray<T>(from data: Data, table: Table) throws -> [T] where T : Viewable {
        return try self.decode(data: data)
    }
    
}
