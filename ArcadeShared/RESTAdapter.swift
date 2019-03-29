//
//  RESTAdapter.swift
//  Arcade
//
//  Created by Aaron Wright on 9/28/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public enum RESTAdapterError: Error {
    case methodNotSupported
    case urlError
    case encodeError
    case responseError
    case noData
    case noResponse
    case HTTPResponse(code: Int, error: Error?)
}

open class RESTAdapter {
    
    public var configuration: RESTConfiguration
    
    // MARK: - Lifecycle
    
    public init(configuration: RESTConfiguration) {
        self.configuration = configuration
    }
    
}

extension RESTAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func disconnect() -> Future<Bool> {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func insert<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        return Future<I> { completion in
            guard let url = self.url(forTable: I.table, uuid: nil, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            do {
                guard let data = try self.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError))
                    return
                }
                
                let urlRequest = self.urlRequest(forURL: url, method: "POST", data: data)
                
                self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard let response = response as? HTTPURLResponse else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noResponse))
                        }
                        return
                    }
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error)))
                        }
                        return
                    }
                    
                    guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                        }
                        return
                    }
                    
                    switch responseCode {
                    case .Created:
                        if let data = data {
                            do {
                                let storable = try self.decodeViewable(from: data, table: I.table) as I
                                DispatchQueue.main.async { completion(.success(storable)) }
                            } catch {
                                DispatchQueue.main.async { completion(.failure(error)) }
                            }
                        } else {
                            DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData)) }
                        }
                    default:
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                        }
                    }
                }.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert<I>(storables: [I], options: [QueryOption] = []) -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func find<I>(uuid: String, options: [QueryOption] = []) -> Future<I?> where I : Viewable {
        return Future<I?> { completion in
            guard let url = self.url(forTable: I.table, uuid: uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    if let data = data {
                        do {
                            let viewable = try self.decodeViewable(from: data, table: I.table) as I
                            DispatchQueue.main.async { completion(.success(viewable)) }
                        } catch {
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noData))
                        }
                    }
                case .NotFound:
                    DispatchQueue.main.async {
                        completion(.success(nil))
                    }
                case .NoContent:
                    DispatchQueue.main.async {
                        completion(.success(nil))
                    }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        return Future<[I]> { completion in
            let expression = Expression.inside("uuid", uuids)
            let query = Query.expression(expression)
            
            var urlComponents: URLComponents
            
            do {
                urlComponents = try self.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = self.url(forTable: I.table, uuid: nil, urlComponents: urlComponents, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    if let data = data {
                        do {
                            let viewables = try self.decodeArray(from: data, table: I.table) as [I]
                            DispatchQueue.main.async { completion(.success(viewables)) }
                        } catch {
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    } else {
                        DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData)) }
                    }
                case .NotFound:
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                case .NoContent:
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func fetch<I>(query: Query?, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0, options: options)
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        return Future<[I]> { completion in
            var urlComponents: URLComponents
            
            do {
                urlComponents = try self.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = self.url(forTable: I.table, uuid: nil, urlComponents: urlComponents, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    guard let data = data else { completion(.failure(RESTAdapterError.noData)); return }
                    
                    do {
                        let viewables = try self.decodeArray(from: data, table: I.table) as [I]
                        DispatchQueue.main.async { completion(.success(viewables)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                case .NoContent:
                    DispatchQueue.main.async { completion(.success([])) }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func update<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        return Future<I> { completion in
            guard let url = self.url(forTable: I.table, uuid: storable.uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            do {
                guard let data = try self.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError))
                    return
                }
                
                let urlRequest = self.urlRequest(forURL: url, method: "PUT", data: data)
                
                self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard let response = response as? HTTPURLResponse else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noResponse))
                        }
                        return
                    }
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error!)))
                        }
                        return
                    }
                    
                    guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                        }
                        return
                    }
                    
                    switch responseCode {
                    case .OK:
                        if let data = data {
                            do {
                                let storable = try self.decodeViewable(from: data, table: I.table) as I
                                DispatchQueue.main.async { completion(.success(storable)) }
                            } catch {
                                DispatchQueue.main.async { completion(.failure(error)) }
                            }
                        } else {
                            DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData)) }
                        }
                    default:
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                        }
                    }
                }.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func update<I>(storables: [I], options: [QueryOption] = []) -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let url = self.url(forTable: I.table, uuid: uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "DELETE", data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .NoContent:
                    DispatchQueue.main.async { completion(.success(true)) }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func delete<I>(uuids: [String], type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func count<T>(table: T, options: [QueryOption]) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption]) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    // MARK: - Helpers
    
    public func url(forTable table: Table?, uuid: String?, urlComponents: URLComponents = URLComponents(), options: [QueryOption]) -> URL? {
        var urlComponents = urlComponents
        urlComponents.scheme = self.configuration.apiScheme
        
        if let table = table {
            urlComponents.host = self.configuration.apiHost
            urlComponents.path = self.configuration.apiPath != nil ? "/\(self.configuration.apiPath!)/\(table.name)" : "/\(table.name)"
            urlComponents.port = self.configuration.apiPort
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
    
    public func urlComponents(forQuery query: Query?, search: String?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) throws -> URLComponents {
        var urlComponents = URLComponents()
        
        urlComponents.queryItems = try RESTQueryBuilder(query: query, search: search, sorts: sorts, limit: limit, offset: offset).queryItems()
        
        return urlComponents
    }
    
    public func urlRequest(forURL url: URL, method: String, data: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        if let key = self.configuration.apiKey { headers["Authorization"] = "Bearer \(key)" }
        
        request.allHTTPHeaderFields = headers
        request.httpBody = data
        
        return request
    }
    
    public func encode<T>(value: T) throws -> Data? where T : Encodable {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try encoder.encode(value)
    }
    
    public func decode<T>(data: Data) throws -> T where T : Decodable {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func decodeViewable<T>(from data: Data, table: Table) throws -> T where T : Viewable {
        return try self.decode(data: data)
    }
    
    public func decodeArray<T>(from data: Data, table: Table) throws -> [T] where T : Viewable {
        return try self.decode(data: data)
    }
    
}
