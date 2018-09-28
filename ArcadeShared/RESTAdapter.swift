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
}

open class RESTAdapter {
    
    private var session: URLSession?
    
    public var apiKey: String
    public var apiScheme: String
    public var apiHost: String
    public var apiPath: String?
    
    // MARK: - Lifecycle
    
    public init(apiKey: String, apiScheme: String, apiHost: String, apiPath: String?, session: URLSession = URLSession(configuration: URLSessionConfiguration.default)) {
        self.apiKey = apiKey
        self.apiScheme = apiScheme
        self.apiHost = apiHost
        self.apiPath = apiPath
        self.session = session
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
    
    public func insert<I>(storable: I) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let url = self.url(forTable: I.table, uuid: nil) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            do {
                guard let data = try self.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError))
                    return
                }
                
                let urlRequest = self.urlRequest(forURL: url, method: "POST", data: data)
                
                self.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard error == nil else {
                        DispatchQueue.main.async { completion(.failure(error!)) }
                        return
                    }
                    
                    DispatchQueue.main.async { completion(.success(true)) }
                }.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert<I>(storables: [I]) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func find<I>(uuid: String) -> Future<I?> where I : Storable {
        return Future<I?> { completion in
            guard let url = self.url(forTable: I.table, uuid: uuid) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async { completion(.failure(error!)) }
                    return
                }
                
                if let data = data {
                    do {
                        let storable = try self.decodeStorable(from: data, table: I.table) as I
                        DispatchQueue.main.async { completion(.success(storable)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                } else {
                    completion(.failure(RESTAdapterError.noData))
                }
            }.resume()
        }
    }
    
    public func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int) -> Future<[I]> where I : Storable {
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
            
            guard let url = self.url(forTable: I.table, uuid: nil, urlComponents: urlComponents) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async { completion(.failure(error!)) }
                    return
                }
                
                if let data = data {
                    do {
                        let storables = try self.decodeArray(from: data, table: I.table) as [I]
                        DispatchQueue.main.async { completion(.success(storables)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                } else {
                    completion(.failure(RESTAdapterError.noData))
                }
            }.resume()
        }
    }
    
    public func fetch<I>(query: Query?) -> Future<[I]> where I : Storable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0)
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int) -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            var urlComponents: URLComponents
            
            do {
                urlComponents = try self.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = self.url(forTable: I.table, uuid: nil, urlComponents: urlComponents) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async { completion(.failure(error!)) }
                    return
                }
                
                guard let data = data else { completion(.failure(RESTAdapterError.noData)); return }
                
                do {
                    let storables = try self.decodeArray(from: data, table: I.table) as [I]
                    DispatchQueue.main.async { completion(.success(storables)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }.resume()
        }
    }
    
    public func update<I>(storable: I) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let url = self.url(forTable: I.table, uuid: storable.uuid) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            do {
                guard let data = try self.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError))
                    return
                }
                
                let urlRequest = self.urlRequest(forURL: url, method: "PUT", data: data)
                
                self.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard error == nil else {
                        DispatchQueue.main.async { completion(.failure(error!)) }
                        return
                    }
                    
                    DispatchQueue.main.async { completion(.success(true)) }
                }.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func update<I>(storables: [I]) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let url = self.url(forTable: I.table, uuid: uuid) else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "DELETE", data: nil)
            
            self.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async { completion(.failure(error!)) }
                    return
                }
                
                DispatchQueue.main.async { completion(.success(true)) }
            }.resume()
        }
    }
    
    public func delete<I>(uuids: [String], type: I.Type) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported))
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        return self.count(table: table, query: query, search: nil)
    }
    
    public func count<T>(table: T, query: Query?, search: String?) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            var urlComponents: URLComponents
            
            do {
                urlComponents = try self.urlComponents(forQuery: query, search: search, sorts: [], limit: 1, offset: 0)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = self.url(forTable: table, uuid: nil, urlComponents: urlComponents)?.appendingPathComponent("count") else {
                completion(.failure(RESTAdapterError.urlError))
                return
            }
            
            let urlRequest = self.urlRequest(forURL: url, method: "GET", data: nil)
            
            self.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async { completion(.failure(error!)) }
                    return
                }
                
                guard let data = data else { completion(.failure(RESTAdapterError.noData)); return }
                
                do {
                    guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Int] else {
                        completion(.failure(RESTAdapterError.noData)); return
                    }
                    
                    if let count = object["count"] {
                        DispatchQueue.main.async { completion(.success(count)) }
                    } else {
                        DispatchQueue.main.async { completion(.failure(RESTAdapterError.responseError)) }
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
    }
    
    // MARK: - Helpers
    
    func url(forTable table: Table?, uuid: String?, urlComponents: URLComponents = URLComponents()) -> URL? {
        var urlComponents = urlComponents
        urlComponents.scheme = self.apiScheme
        
        if let table = table {
            urlComponents.host = self.apiHost
            urlComponents.path = "/\(self.apiHost)/\(table.name)"
        }
        
        let path = urlComponents.path
        
        if let uuid = uuid { urlComponents.path = "\(path)/\(uuid)" }
        
        return urlComponents.url
    }
    
    func urlComponents(forQuery query: Query?, search: String?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) throws -> URLComponents {
        var urlComponents = URLComponents()
        
        urlComponents.queryItems = try RESTQueryBuilder(query: query, search: search, sorts: sorts, limit: limit, offset: offset).queryItems()
        
        return urlComponents
    }
    
    func urlRequest(forURL url: URL, method: String, data: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        headers["Authorization"] = "Bearer \(self.apiKey)"
        
        request.allHTTPHeaderFields = headers
        request.httpBody = data
        
        return request
    }
    
    func encode<T>(value: T) throws -> Data? where T : Encodable {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try encoder.encode(value)
    }
    
    func decodeStorable<T>(from data: Data, table: Table) throws -> T where T : Storable {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
    
    func decodeArray<T>(from data: Data, table: Table) throws -> [T] where T : Storable {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode([T].self, from: data)
    }
    
}
