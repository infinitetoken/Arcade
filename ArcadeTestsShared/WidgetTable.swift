//
//  WidgetTable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

enum WidgetTable: String, Table {
    case widget = "WidgetEntity"
    
    var name: String {
        return self.rawValue
    }
}
