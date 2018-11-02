//
//  HTTPResponseCodes.swift
//  Arcade
//
//  Created by Paul Foster on 11/2/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation


public enum HTTPResponseCodes: Int {
    case ok = 200
    case created = 201
    case noContent = 204
    case badRequest = 400
    case unauthorized = 401
    case notFound = 404
    case unprocessableEntity = 422
    case internalServerError = 500
}
