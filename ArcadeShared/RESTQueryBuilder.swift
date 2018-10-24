//
//  RESTQueryBuilder.swift
//  Arcade
//
//  Created by Aaron Wright on 9/28/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct RESTQueryBuilder {
    
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
        
        var sortDictionary: [String: Any] = [:]
        
        for sort in self.sorts {
            sortDictionary = sortDictionary.merging(sort.dictionary) { (key, _) in key }
        }
        
        guard let jsonString = try sortDictionary.jsonString() else { return nil }
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
        case .expression(let expression):
            return self.validateExpression(expression: expression)
        case .and(let expressions):
            return !expressions.map({ (expression) -> Bool in
                self.validateExpression(expression: expression)
            }).contains(false)
        case .or(let expressions):
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
