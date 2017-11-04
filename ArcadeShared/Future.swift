//
//  Future.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public struct Future<T> {
    
    
    
    public typealias ResultType = Result<T>
    
    
    
    
    private let operation: ( @escaping (ResultType) -> ()) -> ()
    
    
    
    
    public init(_ result: ResultType) {
        self.init(operation: { completion in
            completion(result)
        })
    }
    
    
    public init(_ value: T) {
        self.init(.success(value))
    }
    
    
    public init(_ error: Error) {
        self.init(.failure(error))
    }
    
    
    public init(operation: @escaping ( @escaping (ResultType) -> ()) -> ()) {
        self.operation = operation
    }
    
    
    
    
    fileprivate func then(_ completion: @escaping (ResultType) -> ()) {
        self.operation() { result in
            completion(result)
        }
    }
    
    
    
    
    public func subscribe(onNext: @escaping (T) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) {
        self.then { result in
            switch result {
            case .success(let value): onNext(value)
            case .failure(let error): onError(error)
            }
        }
    }
}




extension Future {
    
    
    
    public func map<U>(_ f: @escaping (T) throws -> U) -> Future<U> {
        return Future<U>(operation: { completion in
            self.then { result in
                switch result {
                    
                case .success(let resultValue):
                    do {
                        let transformedValue = try f(resultValue)
                        completion(.success(transformedValue))
                    } catch let error {
                        completion(.failure(error))
                    }
                    
                case .failure(let errorBox):
                    completion(.failure(errorBox))
                    
                }
            }
        })
    }

    
    public func flatMap<U>(_ f: @escaping (T) -> Future<U>) -> Future<U> {
        return Future<U>(operation: { completion in
            self.then { firstFutureResult in
                switch firstFutureResult {
                case .success(let value): f(value).then(completion)
                case .failure(let error): completion(.failure(error))
                }
            }
        })
    }
}
