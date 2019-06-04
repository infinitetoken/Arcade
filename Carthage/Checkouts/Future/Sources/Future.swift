//
//  Future.swift
//  Future
//
//  Created by Aaron Wright on 8/17/18.
//  Copyright © 2018 Aaron Wright. All rights reserved.
//

import Foundation

postfix operator **

public postfix func **<T>(_ futures: [Future<T>]) -> Future<[T]> {
    var futures = futures
    var values: [T] = []
    
    func result() -> Future<[T]> {
        guard let future = futures.popLast() else { return Future<[T]>(values) }
        
        return future.then { (value) -> Future<[T]> in
            values.append(value)
            return result()
        }
    }
    
    return result()
}

public func merge<T>(_ futures: [Future<T>]) -> Future<[T]> {
    var futures = futures
    var values: [T] = []
    
    func result() -> Future<[T]> {
        guard let future = futures.popLast() else { return Future<[T]>(values) }
        
        return future.then { (value) -> Future<[T]> in
            values.append(value)
            return result()
        }
    }
    
    return result()
}

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public struct Future<T> {
    
    public typealias ResultType = Result<T>
    
    private let operation: ( @escaping (ResultType) -> ()) -> ()
    
    public init(_ result: ResultType) {
        self.init { $0(result) }
    }
    
    public init(_ value: T) {
        self.init(.success(value))
    }
    
    public init(_ error: Error) {
        self.init(.failure(error))
    }
    
    public init(_ operation: @escaping ( @escaping (ResultType) -> ()) -> ()) {
        self.operation = operation
    }
    
    fileprivate func next(_ completion: @escaping (ResultType) -> ()) {
        self.operation() { completion($0) }
    }
    
    public func subscribe(_ onComplete: @escaping (T) -> Void = { _ in }, _ onError: @escaping (Error) -> Void = { _ in }) {
        self.next { result in
            switch result {
            case .success(let value): onComplete(value)
            case .failure(let error): onError(error)
            }
        }
    }
    
    public func subscribe(_ onComplete: @escaping (T) -> Void = { _ in }, _ onError: @escaping (Error) -> Void = { _ in }, always: @escaping () -> Void = {}) {
        self.next { result in
            switch result {
            case .success(let value): onComplete(value)
            case .failure(let error): onError(error)
            }
            always()
        }
    }
    
    public func subscribe(_ onComplete: @escaping (T) -> Void = { _ in }, _ onError: @escaping (Error) -> Void = { _ in }, before: @escaping () -> Void = {}, after: @escaping () -> Void = {}) {
        self.next { result in
            before()
            switch result {
            case .success(let value): onComplete(value)
            case .failure(let error): onError(error)
            }
            after()
        }
    }
    
    public func subscribe( _ onError: @escaping (Error) -> Void = { _ in }) {
        self.next { result in
            switch result {
            case .success(_): break
            case .failure(let error): onError(error)
            }
        }
    }
    
    public func subscribe( _ onError: @escaping (Error) -> Void = { _ in }, always: @escaping () -> Void = {}) {
        self.next { result in
            switch result {
            case .success(_): break
            case .failure(let error): onError(error)
            }
        }
        always()
    }
    
}

extension Future {
    
    public func transform<U>(_ f: @escaping (T) throws -> U) -> Future<U> {
        return Future<U> { completion in
            self.next { result in
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
        }
    }
    
    public func then<U>(_ f: @escaping (T) -> Future<U>) -> Future<U> {
        return Future<U> { completion in
            self.next { firstFutureResult in
                switch firstFutureResult {
                case .success(let value): f(value).next(completion)
                case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
    
    public func then<U,V>(condition: Bool, ifTrue: @escaping (T) -> Future<(U?,V?)>, ifFalse: @escaping (T) -> Future<(U?,V?)>) -> Future<(U?,V?)> {
        if condition {
            return Future<(U?,V?)> { completion in
                self.next { result in
                    switch result {
                    case .success(let value): ifTrue(value).next(completion)
                    case .failure(let error): completion(.failure(error))
                    }
                }
            }
        } else {
            return Future<(U?,V?)> { completion in
                self.next { result in
                    switch result {
                    case .success(let value): ifFalse(value).next(completion)
                    case .failure(let error): completion(.failure(error))
                    }
                }
            }
        }
    }
    
    public func then<U>(condition: Bool, ifTrue: @escaping (T) -> Future<U?>, ifFalse: @escaping (T) -> Future<U?>) -> Future<U?> {
        if condition {
            return Future<U?> { completion in
                self.next { result in
                    switch result {
                    case .success(let value): ifTrue(value).next(completion)
                    case .failure(let error): completion(.failure(error))
                    }
                }
            }
        } else {
            return Future<U?> { completion in
                self.next { result in
                    switch result {
                    case .success(let value): ifFalse(value).next(completion)
                    case .failure(let error): completion(.failure(error))
                    }
                }
            }
        }
    }
    
    public func merge<U>(with future: Future<U>) -> Future<(T, U)> {
        return then { (value) -> Future<(T, U)> in
            future.then({ (valueTwo) -> Future<(T, U)> in
                return Future<(T, U)>((value, valueTwo))
            })
        }
    }
    
    public func merge(with futures: [Future<T>]) -> Future<[T]> {
        var futures = futures
        var values: [T] = []
        
        func result() -> Future<[T]> {
            guard let future = futures.popLast() else { return Future<[T]>(values) }
            
            return future.then { (value) -> Future<[T]> in
                values.append(value)
                return result()
            }
        }
        
        return self.then { (value) -> Future<[T]> in
            values.append(value)
            return result()
        }
    }
    
}

