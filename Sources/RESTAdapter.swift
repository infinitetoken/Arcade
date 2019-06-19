//
//  RESTAdapter.swift
//  Arcade
//
//  Created by Aaron Wright on 9/28/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

open class RESTAdapter {
    
    public enum AdapterError: LocalizedError {
        case methodNotSupported(function: AdapterFunction, table: Table?)
        case urlError(function: AdapterFunction, table: Table?)
        case encodeError(function: AdapterFunction, table: Table?)
        case responseError(function: AdapterFunction, table: Table?)
        case noData(function: AdapterFunction, table: Table?)
        case noResponse(function: AdapterFunction, table: Table?)
        case noContent(function: AdapterFunction, table: Table?)
        case notFound(function: AdapterFunction, table: Table?)
        case HTTPResponse(function: AdapterFunction, table: Table?, code: Int, error: Error?)
        
        public var errorDescription: String? {
            switch self {
            case .methodNotSupported(let function, let table):
                return "Method not supported: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .urlError(let function, let table):
                return "URL error: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .encodeError(let function, let table):
                return "Encode error: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .responseError(let function, let table):
                return "Response error: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .noData(let function, let table):
                return "No data: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .noResponse(let function, let table):
                return "No response: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .noContent(let function, let table):
                return "No content: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .notFound(let function, let table):
                return "Not found: \(function.rawValue) -> \(table?.name ?? "Unknown")"
            case .HTTPResponse(let function, let table, let code, let error):
                return "HTTP error: \(function.rawValue) -> \(table?.name ?? "Unknown") -> \(code) -> \(error?.localizedDescription ?? "")"
            }
        }
    }
    
    public enum AdapterFunction: String {
        case connect = "Connect"
        case disconnect = "Disconnect"
        case count = "Count"
        case find = "Find"
        case fetch = "Fetch"
        case insert = "Insert"
        case delete = "Delete"
        case update = "Update"
    }
    
    public enum AdapterAuthorization {
        case token(String)
        case credentials(String, String)
    }
    
    public var configuration: RESTConfiguration
    public var authorization: AdapterAuthorization?
    
    // MARK: - Lifecycle
    
    public init(configuration: RESTConfiguration, authorization: AdapterAuthorization) {
        self.configuration = configuration
        self.authorization = authorization
    }
    
}

extension RESTAdapter: Adapter {
    
    public func connect(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(AdapterError.methodNotSupported(function: .connect, table: nil)))
    }
    
    public func disconnect(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(AdapterError.methodNotSupported(function: .disconnect, table: nil)))
    }
    
    public func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: nil, options: options) else {
            completion(.failure(AdapterError.urlError(function: .insert, table: storable.table)))
            return
        }
        
        do {
            guard let data = try RESTHelper.encode(value: storable) else {
                completion(.failure(AdapterError.encodeError(function: .insert, table: storable.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: .post, authorization: self.authorization, data: data)
            
            self.configuration.session.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.noResponse(function: .insert, table: storable.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: error)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: nil)))
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
                        DispatchQueue.main.async { completion(.failure(AdapterError.noData(function: .insert, table: storable.table))) }
                    }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    public func find<I>(uuid: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: uuid, options: options) else {
            completion(.failure(AdapterError.urlError(function: .find, table: I.table)))
            return
        }
        
        let urlRequest = RESTHelper.urlRequest(forURL: url, method: .get, authorization: self.authorization, data: nil)
        
        self.configuration.session.dataTask(with: urlRequest) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.noResponse(function: .find, table: I.table)))
                }
                return
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: error!)))
                }
                return
            }
            
            guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
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
                        completion(.failure(AdapterError.noData(function: .find, table: I.table)))
                    }
                }
            case .NotFound:
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.notFound(function: .find, table: I.table)))
                }
            case .NoContent:
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.noContent(function: .find, table: I.table)))
                }
            default:
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
                }
            }
        }.resume()
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        var urlComponents: URLComponents
        
        do {
            urlComponents = try RESTHelper.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
        } catch {
            completion(.failure(error))
            return
        }
        
        guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: nil, urlComponents: urlComponents, options: options) else {
            completion(.failure(AdapterError.urlError(function: .fetch, table: I.table)))
            return
        }
        
        let urlRequest = RESTHelper.urlRequest(forURL: url, method: .get, authorization: self.authorization, data: nil)
        
        self.configuration.session.dataTask(with: urlRequest) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.noResponse(function: .fetch, table: I.table)))
                }
                return
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: error!)))
                }
                return
            }
            
            guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: nil)))
                }
                return
            }
            
            switch responseCode {
            case .OK:
                guard let data = data else { completion(.failure(AdapterError.noData(function: .fetch, table: I.table))); return }
                
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
                    completion(.failure(AdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: nil)))
                }
            }
        }.resume()
    }
    
    public func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: storable.uuid, options: options) else {
            completion(.failure(AdapterError.urlError(function: .update, table: I.table)))
            return
        }
        
        do {
            guard let data = try RESTHelper.encode(value: storable) else {
                completion(.failure(AdapterError.encodeError(function: .update, table: I.table)))
                return
            }
            
            let urlRequest = RESTHelper.urlRequest(forURL: url, method: .put, authorization: self.authorization, data: data)
            
            self.configuration.session.dataTask(with: urlRequest) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.noResponse(function: .update, table: I.table)))
                    }
                    return
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: error!)))
                    }
                    return
                }
                
                guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: nil)))
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
                        DispatchQueue.main.async { completion(.failure(AdapterError.noData(function: .update, table: I.table))) }
                    }
                default:
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: nil)))
                    }
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard let url = RESTHelper.url(configuration: self.configuration, forTable: I.table, uuid: uuid, options: options) else {
            completion(.failure(AdapterError.urlError(function: .delete, table: I.table)))
            return
        }
        
        let urlRequest = RESTHelper.urlRequest(forURL: url, method: .delete, authorization: self.authorization, data: nil)
        
        self.configuration.session.dataTask(with: urlRequest) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.noResponse(function: .delete, table: I.table)))
                }
                return
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: error!)))
                }
                return
            }
            
            guard let responseCode = RESTResponseCodes(rawValue: response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: nil)))
                }
                return
            }
            
            switch responseCode {
            case .NoContent:
                DispatchQueue.main.async { completion(.success(true)) }
            default:
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .delete, table: I.table, code: response.statusCode, error: nil)))
                }
            }
        }.resume()
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T: Table {
        completion(.failure(AdapterError.methodNotSupported(function: .count, table: table)))
    }
    
}
