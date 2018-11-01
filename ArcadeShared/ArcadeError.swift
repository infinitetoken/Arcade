//
//  ArcadeError.swift
//  Arcade
//
//  Created by Paul Foster on 11/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation


public enum ArcadeError: Error {
    case HTTPResponse(code: Int, error: Error)
}
