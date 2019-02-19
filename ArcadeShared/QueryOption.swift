//
//  QueryOption.swift
//  Arcade
//
//  Created by Paul Foster on 2/19/19.
//  Copyright © 2019 A.C. Wright Design. All rights reserved.
//

import Foundation


public protocol QueryOption {
    
    var key: String { get set }
    var value: Codable { get set }
    
}
