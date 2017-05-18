//
//  Utilities.swift
//  SwiftyBeaverProvider
//
//  Created by Gustavo Perdomo on 5/2/17.
//  Copyright © 2017 Gustavo Perdomo. All rights reserved.
//

// swiftlint:disable force_try

import Foundation
@testable import AppExample
@testable import Vapor
import XCTest
import Testing

extension Droplet {
    static func testable() throws -> Droplet {
        let config = try Config(arguments: ["vapor", "--env=test"])
        try config.setup()
        let drop = try Droplet(config)
        try drop.setup()
        return drop
    }
    func serveInBackground() throws {
        background {
            try! self.run()
        }
        console.wait(seconds: 0.5)
    }
}

class TestCase: XCTestCase {
    override func setUp() {
        Testing.onFail = XCTFail
    }
}
