//
//  Logging.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import os

enum Log {
    private static let subsystem = "org.agaafar.Island"
    
    static let app          = Logger(subsystem: subsystem, category: "App")
    static let power        = Logger(subsystem: subsystem, category: "Power")
    static let audio        = Logger(subsystem: subsystem, category: "Audio")
    static let wifi         = Logger(subsystem: subsystem, category: "WiFi")
    static let screenshot   = Logger(subsystem: subsystem, category: "Screenshot")
    static let clipboard    = Logger(subsystem: subsystem, category: "Clipboard")
    static let camera       = Logger(subsystem: subsystem, category: "Camera")
    static let location     = Logger(subsystem: subsystem, category: "Location")
}
