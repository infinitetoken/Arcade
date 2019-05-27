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
    case methodNotSupported(function: AdapterFunction, table: Table?)
    case urlError(function: AdapterFunction, table: Table?)
    case encodeError(function: AdapterFunction, table: Table?)
    case responseError(function: AdapterFunction, table: Table?)
    case noData(function: AdapterFunction, table: Table?)
    case noResponse(function: AdapterFunction, table: Table?)
    case noContent(function: AdapterFunction, table: Table?)
    case notFound(function: AdapterFunction, table: Table?)
    case HTTPResponse(function: AdapterFunction, table: Table?, code: Int, error: Error?)
}

public enum AdapterFunction: String {
    case connect = "connect"
    case disconnect = "disconnect"
    case count = "count"
    case find = "find"
    case fetch = "fetch"
    case insert = "insert"
    case delete = "delete"
    case update = "update"
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
            completion(.failure(RESTAdapterError.methodNotSupported(function: .connect, table: nil)))
        }
    }
    
    public func disconnect() -> Future<Bool> {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported(function: .disconnect, table: nil)))
        }
    }
    
    public func insert<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        return Future<I> { completion in
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: nil, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .insert, table: storable.table)))
                return
            }
            
            do {
                guard let data = try RESTHelper.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError(function: .insert, table: storable.table)))
                    return
                }
                
                let urlRequest = RESTHelper.urlRequest(forURL: url, method: "POST", token: self.configuration.apiKey, data: data)
                
                self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard let response = response as? HTTPURLResponse else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noResponse(function: .insert, table: storable.table)))
                        }
                        return
                    }
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: error)))
                        }
                        return
                    }
                    
                    guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: nil)))
                        }
                        return
                    }
                    
                    switch responseCode {
                    case .Created:
                        if let data = data {
                            do {
                                let storable = try RESTHelper.decodeViewable(from: data, table: I.table) as I
                                DispatchQueue.main.async { completion(.success(storable)) }
                            } catch {
                                DispatchQueue.main.async { completion(.failure(error)) }
                            }
                        } else {
                            DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData(function: .insert, table: storable.table))) }
                        }
                    default:
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: nil)))
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
            completion(.failure(RESTAdapterError.methodNotSupported(function: .insert, table: I.table)))
        }
    }
    
    public func find<I>(uuid: String, options: [QueryOption] = []) -> Future<I> where I : Viewable {
        return Future<I> { completion in
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .find, table: I.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: "GET", token: self.configuration.apiKey, data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse(function: .find, table: I.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    if let data = data {
                        do {
                            let viewable = try RESTHelper.decodeViewable(from: data, table: I.table) as I
                            DispatchQueue.main.async { completion(.success(viewable)) }
                        } catch {
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noData(function: .find, table: I.table)))
                        }
                    }
                case .NotFound:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.notFound(function: .find, table: I.table)))
                    }
                case .NoContent:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noContent(function: .find, table: I.table)))
                    }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        return Future<[I]> { completion in
            let expression = Expression.inside("id", uuids)
            let query = Query.expression(expression)
            
            var urlComponents: URLComponents
            
            do {
                urlComponents = try RESTHelper.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: nil, urlComponents: urlComponents, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .find, table: I.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: "GET", token: self.configuration.apiKey, data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse(function: .find, table: I.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    if let data = data {
                        do {
                            let viewables = try RESTHelper.decodeArray(from: data, table: I.table) as [I]
                            DispatchQueue.main.async { completion(.success(viewables)) }
                        } catch {
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    } else {
                        DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData(function: .find, table: I.table))) }
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
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
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
                urlComponents = try RESTHelper.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: nil, urlComponents: urlComponents, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .fetch, table: I.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: "GET", token: self.configuration.apiKey, data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse(function: .fetch, table: I.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .OK:
                    guard let data = data else { completion(.failure(RESTAdapterError.noData(function: .fetch, table: I.table))); return }
                    
                    do {
                        let viewables = try RESTHelper.decodeArray(from: data, table: I.table) as [I]
                        DispatchQueue.main.async { completion(.success(viewables)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                case .NoContent:
                    DispatchQueue.main.async { completion(.success([])) }
                case .UnprocessableEntity:
                    DispatchQueue.main.async { completion(.success([])) }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func update<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        return Future<I> { completion in
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: storable.uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .update, table: I.table)))
                return
            }
            
            do {
                guard let data = try RESTHelper.encode(value: storable) else {
                    completion(.failure(RESTAdapterError.encodeError(function: .update, table: I.table)))
                    return
                }
                
                let urlRequest = RESTHelper.urlRequest(forURL: url, method: "PUT", token: self.configuration.apiKey, data: data)
                
                self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                    guard let response = response as? HTTPURLResponse else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.noResponse(function: .update, table: I.table)))
                        }
                        return
                    }
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: error!)))
                        }
                        return
                    }
                    
                    guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: nil)))
                        }
                        return
                    }
                    
                    switch responseCode {
                    case .OK:
                        if let data = data {
                            do {
                                let storable = try RESTHelper.decodeViewable(from: data, table: I.table) as I
                                DispatchQueue.main.async { completion(.success(storable)) }
                            } catch {
                                DispatchQueue.main.async { completion(.failure(error)) }
                            }
                        } else {
                            DispatchQueue.main.async { completion(.failure(RESTAdapterError.noData(function: .update, table: I.table))) }
                        }
                    default:
                        DispatchQueue.main.async {
                            completion(.failure(RESTAdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: nil)))
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
            completion(.failure(RESTAdapterError.methodNotSupported(function: .update, table: I.table)))
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: uuid, options: options) else {
                completion(.failure(RESTAdapterError.urlError(function: .delete, table: I.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: "DELETE", token: self.configuration.apiKey, data: nil)
            
            self.configuration.session?.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.noResponse(function: .delete, table: I.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: nil)))
                    }
                    return
                }
                
                switch responseCode {
                case .NoContent:
                    DispatchQueue.main.async { completion(.success(true)) }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(RESTAdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        }
    }
    
    public func delete<I>(uuids: [String], type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported(function: .delete, table: I.table)))
        }
    }
    
    public func count<T>(table: T, options: [QueryOption]) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported(function: .count, table: table)))
        }
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption]) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            completion(.failure(RESTAdapterError.methodNotSupported(function: .count, table: table)))
        }
    }
    
}
