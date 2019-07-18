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
    
    public struct AdapterConfiguration {
        
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
    
    public enum AdapterAuthorization {
        case token(String)
        case credentials(String, String)
    }
    
    public enum AdapterResponseCodes: Int {
        case Continue = 100
        case SwitchingProtocols = 101
        case Processing = 102
        
        case OK = 200
        case Created = 201
        case Accepted = 202
        case NonAuthoratativeInformation = 203
        case NoContent = 204
        case ResetContent = 205
        case PartialContent = 206
        case MultiStatus = 207
        case AlreadyReported = 208
        case IMUsed = 226
        
        case MultipleChoices = 300
        case MovedPermanently = 301
        case Found = 302
        case SeeOther = 303
        case NotModified = 304
        case UseProxy = 305
        case TemporaryRedirect = 307
        case PermanentRedirect = 308
        
        case BadRequest = 400
        case Unauthorized = 401
        case PaymentRequired = 402
        case Forbidden = 403
        case NotFound = 404
        case MethodNotAllowed = 405
        case NotAcceptable = 406
        case ProxyAuthenticationRequired = 407
        case RequestTimeout = 408
        case Conflict = 409
        case Gone = 410
        case LengthRequired = 411
        case PreconditionFailed = 412
        case RequestEntityTooLarge = 413
        case RequestURITooLong = 414
        case UnsupportedMediaType = 415
        case RequestedRangeNotSatisfiable = 416
        case ExpectationFailed = 417
        case ImATeapot = 418
        case EnhanceYourCalm = 420
        case UnprocessableEntity = 422
        case Locked = 423
        case FailedDependency = 424
        case Reserved = 425
        case UpgradeRequired = 426
        case PreconditionRequired = 428
        case TooManyRequests = 429
        case RequestHeaderFieldsTooLarge = 431
        case NoResponse = 444
        case RetryWith = 449
        case BlockedByWindowsParentalControls = 450
        case UnavailableForLegalReasons = 451
        case ClientClosedRequest = 499
        
        case InternalServerError = 500
        case NotImplemented = 501
        case BadGateway = 502
        case ServiceUnavailable = 503
        case GatewayTimeout = 504
        case HTTPVersionNotSupported = 505
        case VariantAlsoNegotiates = 506
        case InsufficientStorage = 507
        case LoopDetected = 508
        case BandwidthLimitExceeded = 509
        case NotExtended = 510
        case NetworkAuthenticationRequired = 511
        case NetworkReadTimeoutError = 598
        case NetworkConnectTimeoutError = 599
    }
    
    public struct AdapterQueryBuilder {
            
        private var query: Query?
        private var search: String?
        private var sorts: [Sort]
        private var limit: Int
        private var offset: Int
        
        public init(query: Query?, search: String?, sorts: [Sort], limit: Int, offset: Int) {
            self.query = query
            self.search = search
            self.sorts = sorts
            self.limit = limit
            self.offset = offset
        }
        
        public func queryItems() throws -> [URLQueryItem] {
            var queryItems: [URLQueryItem] = []
            
            if let queryQueryItem = try self.queryQueryItem() { queryItems.append(queryQueryItem) }
            if let searchQueryItem = try self.searchQueryItem() { queryItems.append(searchQueryItem) }
            if let sortQueryItem = try self.sortQueryItem() { queryItems.append(sortQueryItem) }
            if let limitQueryItem = self.limitQueryItem() { queryItems.append(limitQueryItem) }
            if let offsetQueryItem = self.offsetQueryItem() { queryItems.append(offsetQueryItem) }
            
            return queryItems
        }
        
        public func queryQueryItem() throws -> URLQueryItem? {
            guard let query = self.query else { return nil }
            
            if self.validateQuery(query: query) {
                guard let jsonString = try query.dictionary.jsonString() else { return nil }
                guard let queryString = jsonString.data(using: .utf8)?.base64EncodedString() else { return nil }
                
                return URLQueryItem(name: "filter", value: queryString)
            } else {
                return nil
            }
        }
        
        public func searchQueryItem() throws -> URLQueryItem? {
            guard let search = self.search else { return nil }
            
            let searchDict = [
                "search": search
            ]
            guard let jsonString = try searchDict.jsonString() else { return nil }
            guard let searchString = jsonString.data(using: .utf8)?.base64EncodedString() else { return nil }
            
            return URLQueryItem(name: "search", value: searchString)
        }
        
        public func sortQueryItem() throws -> URLQueryItem? {
            if self.sorts.isEmpty { return nil }
            
            let sortsArray: [[String:Any]] = self.sorts.reduce([]) {
                var result = $0
                result.append($1.dictionary)
                return result
            }
            
            let data = try JSONSerialization.data(withJSONObject: sortsArray, options: .sortedKeys)
            
            guard let jsonString = String(data: data, encoding: .utf8) else { return nil }
            guard let queryString = jsonString.data(using: .utf8)?.base64EncodedString() else { return nil }
            
            return URLQueryItem(name: "sort", value: queryString)
        }
        
        public func limitQueryItem() -> URLQueryItem? {
            if self.limit == 0 { return nil }
            
            return URLQueryItem(name: "limit", value: String(self.limit))
        }
        
        public func offsetQueryItem() -> URLQueryItem? {
            if self.offset == 0 { return nil }
            
            return URLQueryItem(name: "offset", value: String(self.offset))
        }
        
        public func validateQuery(query: Query) -> Bool {
            switch query {
            case .expression(let expression, _, _):
                return self.validateExpression(expression: expression)
            case .and(let expressions, _, _):
                return !expressions.map({ (expression) -> Bool in
                    self.validateExpression(expression: expression)
                }).contains(false)
            case .or(let expressions, _, _):
                return !expressions.map({ (expression) -> Bool in
                    self.validateExpression(expression: expression)
                }).contains(false)
            default:
                return false
            }
        }
        
        public func validateExpression(expression: Expression) -> Bool {
            switch expression {
            case .all:
                return true
            case .search(_):
                return true
            case .isEmpty(_):
                return true
            case .equal(_, _):
                return true
            case .notEqual(_, _):
                return true
            case .isNil(_):
                return true
            case .isNotNil(_):
                return true
            case .inside(_, _):
                return true
            case .like(_, _):
                return true
            case .contains(_, _):
                return true
            case .comparison(_, let comparison, _, let options):
                switch comparison {
                case .inside:
                    return false
                default:
                    return !options.contains(.normalized) || !options.contains(.diacriticInsensitive)
                }
            }
        }
            
    }
    
    public struct AdapterHelper {
        
        public enum Method: String {
            case get = "GET"
            case post = "POST"
            case put = "PUT"
            case patch = "PATCH"
            case delete = "DELETE"
        }
        
        public static func url(configuration: RESTAdapter.AdapterConfiguration, forTable table: Table?, id: String?, urlComponents: URLComponents = URLComponents(), options: [QueryOption] = []) -> URL? {
            var urlComponents = urlComponents
            urlComponents.scheme = configuration.apiScheme
            
            if let table = table {
                urlComponents.host = configuration.apiHost
                urlComponents.path = configuration.apiPath != nil ? "/\(configuration.apiPath!)/\(table.name)" : "/\(table.name)"
                urlComponents.port = configuration.apiPort
            }
            
            if let id = id { urlComponents.path += "/\(id)" }
            
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
        
        public static func url(configuration: RESTAdapter.AdapterConfiguration, forResource resource: String, id: String?, urlComponents: URLComponents = URLComponents(), options: [QueryOption] = []) -> URL? {
            var urlComponents = urlComponents
            urlComponents.scheme = configuration.apiScheme
            urlComponents.host = configuration.apiHost
            urlComponents.path = configuration.apiPath != nil ? "/\(configuration.apiPath!)/\(resource)" : "/\(resource)"
            urlComponents.port = configuration.apiPort
            
            if let id = id { urlComponents.path += "/\(id)" }
            
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
            
            urlComponents.queryItems = try RESTAdapter.AdapterQueryBuilder(query: query, search: search, sorts: sorts, limit: limit, offset: offset).queryItems()
            
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
    
    public var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return encoder
    }
    
    public var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return decoder
    }
    
    public var configuration: AdapterConfiguration
    public var authorization: AdapterAuthorization?
    
    // MARK: - Lifecycle
    
    public init(configuration: AdapterConfiguration, authorization: AdapterAuthorization?) {
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
        guard let url = AdapterHelper.url(configuration: self.configuration, forTable: I.table, id: nil, options: options) else {
            completion(.failure(AdapterError.urlError(function: .insert, table: storable.table)))
            return
        }

        do {
            guard let data = try AdapterHelper.encode(value: storable) else {
                completion(.failure(AdapterError.encodeError(function: .insert, table: storable.table)))
                return
            }

            let urlRequest = AdapterHelper.urlRequest(forURL: url, method: .post, authorization: self.authorization, data: data)

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

                guard let responseCode = AdapterResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .insert, table: storable.table, code: response.statusCode, error: nil)))
                    }
                    return
                }

                switch responseCode {
                case .Created:
                    if let data = data {
                        do {
                            let storable = try AdapterHelper.decodeViewable(from: data, table: I.table) as I
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
    
    public func find<I>(id: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        guard let url = AdapterHelper.url(configuration: self.configuration, forTable: I.table, id: id, options: options) else {
            completion(.failure(AdapterError.urlError(function: .find, table: I.table)))
            return
        }

        let urlRequest = AdapterHelper.urlRequest(forURL: url, method: .get, authorization: self.authorization, data: nil)

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

            guard let responseCode = AdapterResponseCodes(rawValue: response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .find, table: I.table, code: response.statusCode, error: nil)))
                }
                return
            }

            switch responseCode {
            case .OK:
                if let data = data {
                    do {
                        let viewable = try AdapterHelper.decodeViewable(from: data, table: I.table) as I
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
            urlComponents = try AdapterHelper.urlComponents(forQuery: query, search: nil, sorts: sorts, limit: limit, offset: offset)
        } catch {
            completion(.failure(error))
            return
        }

        guard let url = AdapterHelper.url(configuration: self.configuration, forTable: I.table, id: nil, urlComponents: urlComponents, options: options) else {
            completion(.failure(AdapterError.urlError(function: .fetch, table: I.table)))
            return
        }

        let urlRequest = AdapterHelper.urlRequest(forURL: url, method: .get, authorization: self.authorization, data: nil)

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

            guard let responseCode = AdapterResponseCodes(rawValue: response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(AdapterError.HTTPResponse(function: .fetch, table: I.table, code: response.statusCode, error: nil)))
                }
                return
            }

            switch responseCode {
            case .OK:
                guard let data = data else { completion(.failure(AdapterError.noData(function: .fetch, table: I.table))); return }

                do {
                    let viewables = try AdapterHelper.decodeArray(from: data, table: I.table) as [I]
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
        guard let url = AdapterHelper.url(configuration: self.configuration, forTable: I.table, id: storable.id, options: options) else {
            completion(.failure(AdapterError.urlError(function: .update, table: I.table)))
            return
        }

        do {
            guard let data = try AdapterHelper.encode(value: storable) else {
                completion(.failure(AdapterError.encodeError(function: .update, table: I.table)))
                return
            }

            let urlRequest = AdapterHelper.urlRequest(forURL: url, method: .put, authorization: self.authorization, data: data)

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

                guard let responseCode = AdapterResponseCodes(rawValue: response.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(AdapterError.HTTPResponse(function: .update, table: I.table, code: response.statusCode, error: nil)))
                    }
                    return
                }

                switch responseCode {
                case .OK:
                    if let data = data {
                        do {
                            let storable = try AdapterHelper.decodeViewable(from: data, table: I.table) as I
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
    
    public func delete<I>(id: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard let url = AdapterHelper.url(configuration: self.configuration, forTable: I.table, id: id, options: options) else {
            completion(.failure(AdapterError.urlError(function: .delete, table: I.table)))
            return
        }

        let urlRequest = AdapterHelper.urlRequest(forURL: url, method: .delete, authorization: self.authorization, data: nil)

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

            guard let responseCode = AdapterResponseCodes(rawValue: response.statusCode) else {
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
