//
//  ResolverTests.swift
//  SwiftyBeaverProvider
//
//  Created by Gustavo Perdomo on 9/21/17.
//  Copyright © 2017 Gustavo Perdomo. All rights reserved.
//

import XCTest
import JSON
import SwiftyBeaver
import Vapor

@testable import SwiftyBeaverProvider

class ResolverTests: XCTestCase {
    var resolver: Resolver!

    override func setUp() {
        resolver = Resolver()
    }

    func testResolveConsoleDestination() throws {
        let console = ConsoleDestination()

        let json = JSON([
            "type": "console",
            "format": "$M",
            "async": false,
            "levelString": [
                "debug": "D",
                "error": "E",
                "info": "I",
                "verbose": "V",
                "warning": "W"
            ],
            "minLevel": "warning"
            ])

        let destination = try resolver.resolveConsoleDestination(using: json)

        XCTAssertNotNil(destination)
        try assertCommonProperties(console, destination, json)
    }

    func testResolveFileDestination() throws {
        let file = FileDestination()

        let json = JSON([
            "type": "file",
            "path": "file-warnings.log",
            "format": "$MJ",
            "async": false,
            "levelString": [
                "debug": "D",
                "error": "E",
                "info": "I",
                "verbose": "V",
                "warning": "W"
            ],
            "minLevel": "debug"
            ])

        let destination = try resolver.resolveFileDestination(using: json)

        XCTAssertNotNil(destination)

        XCTAssertNotEqual(file.logFileURL, destination.logFileURL)
        XCTAssertTrue((destination.logFileURL?.absoluteString.hasSuffix("file-warnings.log"))!)

        try assertCommonProperties(file, destination, json)
    }
    
    func testInvalidFilePath() throws {
        let json = JSON([
            "type": "file",
            "path": ""
            ])
        
        try assertError(expectedError: ConfigError.unsupported(value: "", key: ["path"], file: CONFIG_FILE_NAME)) {
            _ = try resolver.resolveFileDestination(using: json)
        }
    }

    func testResolveSBPlatformDestination() throws {
        let json = JSON([
            "app": "APP_ID",
            "secret": "SECRET_ID",
            "key": "ENCRYPTION_KEY",
            "threshold": 500,
            "minLevel": "info"
            ])

        let platform = try resolver.resolveSBPlatformDestination(using: json)

        XCTAssertNotNil(platform)

        XCTAssertEqual(platform.appID, "APP_ID")
        XCTAssertEqual(platform.appSecret, "SECRET_ID")
        XCTAssertEqual(platform.encryptionKey, "ENCRYPTION_KEY")

        XCTAssertEqual(platform.sendingPoints.threshold, 500)

        XCTAssertEqual(platform.minLevel, .info)
    }

    func testGetMinLevelFromJSON() throws {
        try assertMinLevel(string: "verbose", expected: SwiftyBeaver.Level.verbose)
        try assertMinLevel(string: "VERBOSE", expected: SwiftyBeaver.Level.verbose)
        try assertMinLevel(string: "   VERBOSE", expected: SwiftyBeaver.Level.verbose)
        try assertMinLevel(string: "VERBOSE   ", expected: SwiftyBeaver.Level.verbose)
        try assertMinLevel(string: " VERbose   ", expected: SwiftyBeaver.Level.verbose)

        try assertMinLevel(string: "debug", expected: SwiftyBeaver.Level.debug)
        try assertMinLevel(string: "DEBUG", expected: SwiftyBeaver.Level.debug)
        try assertMinLevel(string: "   DEBUG", expected: SwiftyBeaver.Level.debug)
        try assertMinLevel(string: "DEBUG   ", expected: SwiftyBeaver.Level.debug)
        try assertMinLevel(string: " deBUG   ", expected: SwiftyBeaver.Level.debug)

        try assertMinLevel(string: "info", expected: SwiftyBeaver.Level.info)
        try assertMinLevel(string: "INFO", expected: SwiftyBeaver.Level.info)
        try assertMinLevel(string: "   INFO", expected: SwiftyBeaver.Level.info)
        try assertMinLevel(string: "INFO   ", expected: SwiftyBeaver.Level.info)
        try assertMinLevel(string: " INfo   ", expected: SwiftyBeaver.Level.info)

        try assertMinLevel(string: "warning", expected: SwiftyBeaver.Level.warning)
        try assertMinLevel(string: "WARNING", expected: SwiftyBeaver.Level.warning)
        try assertMinLevel(string: "   WARNING", expected: SwiftyBeaver.Level.warning)
        try assertMinLevel(string: "WARNING   ", expected: SwiftyBeaver.Level.warning)
        try assertMinLevel(string: " wArNING   ", expected: SwiftyBeaver.Level.warning)

        try assertMinLevel(string: "error", expected: SwiftyBeaver.Level.error)
        try assertMinLevel(string: "ERROR", expected: SwiftyBeaver.Level.error)
        try assertMinLevel(string: "   ERROR", expected: SwiftyBeaver.Level.error)
        try assertMinLevel(string: "ERROR   ", expected: SwiftyBeaver.Level.error)
        try assertMinLevel(string: " ErrOR   ", expected: SwiftyBeaver.Level.error)
    }

    func testInvalidSBPlatformThreshold() throws {
        var json = JSON([
            "app": "APP_ID",
            "secret": "SECRET_ID",
            "key": "ENCRYPTION_KEY",
            "threshold": -1,
            "minLevel": "info"
            ])
        
        try assertError(expectedError: SwiftyBeaverProviderError.thresholdOutOfRange) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }
        
        try json.set("threshold", 1001)

        try assertError(expectedError: SwiftyBeaverProviderError.thresholdOutOfRange) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }

        try json.set("threshold", "abc")
        
        try assertError(expectedError: ConfigError.unsupported(value: "abc", key: ["threshold"], file: CONFIG_FILE_NAME)) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }
    }
    
    func testInvalidSBPlatformApp() throws {
        let json = JSON([
            "app": "",
            "secret": "SECRET_ID",
            "key": "ENCRYPTION_KEY"
            ])
        
        try assertError(expectedError: ConfigError.missing(key: ["app"], file: CONFIG_FILE_NAME, desiredType: String.self)) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }
    }
    
    func testInvalidSBPlatformSecret() throws {
        let json = JSON([
            "app": "APP_ID",
            "secret": "",
            "key": "ENCRYPTION_KEY"
            ])
        
        try assertError(expectedError: ConfigError.missing(key: ["secret"], file: CONFIG_FILE_NAME, desiredType: String.self)) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }
    }
    
    func testInvalidSBPlatformKey() throws {
        let json = JSON([
            "app": "APP_ID",
            "secret": "SECRET_ID",
            "key": ""
            ])
        
        try assertError(expectedError: ConfigError.missing(key: ["key"], file: CONFIG_FILE_NAME, desiredType: String.self)) {
            _ = try resolver.resolveSBPlatformDestination(using: json)
        }
    }

    func testInvalidAsync() throws {
        let json = JSON([
            "type": "console",
            "async": "not-bool"
            ])

        try assertError(expectedError: ConfigError.unsupported(value: "not-bool", key: ["async"], file: CONFIG_FILE_NAME)) {
            _ = try resolver.resolveConsoleDestination(using: json)
        }
    }

    func testInvalidMinLevel() throws {
        let json = JSON([
            "type": "console",
            "minLevel": "not-min-level"
            ])

        try assertError(expectedError: SwiftyBeaverProviderError.invalidMinLevel) {
            _ = try resolver.resolveConsoleDestination(using: json)
        }
    }

    // MARK: Helpers
    func assertMinLevel(string: String, expected: SwiftyBeaver.Level) throws {
        var json = JSON()
        try json.set("minLevel", string)

        let level = try resolver.getMinLevel(from: json)

        XCTAssertEqual(level, expected)
    }

    func assertCommonProperties(_ defaultDestination: BaseDestination, _ destination: BaseDestination, _ json: JSON) throws {
        // format
        XCTAssertNotEqual(defaultDestination.format, destination.format)
        XCTAssertEqual(destination.format, json["format"]?.string)

        // async
        XCTAssertNotEqual(defaultDestination.asynchronously, destination.asynchronously)
        XCTAssertEqual(destination.asynchronously, json["async"]?.bool)

        // minLevel
        XCTAssertNotEqual(defaultDestination.minLevel, destination.minLevel)
        XCTAssertEqual(destination.minLevel, try resolver.getMinLevel(from: json))

        // levelString
        XCTAssertNotEqual(defaultDestination.levelString.debug, destination.levelString.debug)
        XCTAssertEqual(destination.levelString.debug, json["levelString.debug"]?.string)

        XCTAssertNotEqual(defaultDestination.levelString.error, destination.levelString.error)
        XCTAssertEqual(destination.levelString.error, json["levelString.error"]?.string)

        XCTAssertNotEqual(defaultDestination.levelString.info, destination.levelString.info)
        XCTAssertEqual(destination.levelString.info, json["levelString.info"]?.string)

        XCTAssertNotEqual(defaultDestination.levelString.verbose, destination.levelString.verbose)
        XCTAssertEqual(destination.levelString.verbose, json["levelString.verbose"]?.string)

        XCTAssertNotEqual(defaultDestination.levelString.warning, destination.levelString.warning)
        XCTAssertEqual(destination.levelString.warning, json["levelString.warning"]?.string)
    }
    
    func assertError(expectedError: ConfigError, closure: () throws -> Void) throws {
        XCTAssertThrowsError(try closure()) { error in
            guard let e = error as? ConfigError else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(e.description, expectedError.description)
        }
    }
    
    func assertError(expectedError: SwiftyBeaverProviderError, closure: () throws -> Void) throws {
        XCTAssertThrowsError(try closure()) { error in
            XCTAssertEqual(error as? SwiftyBeaverProviderError, expectedError)
        }
    }
}

// MARK: Manifest

extension ResolverTests {
    func testLinuxTestSuiteIncludesAllTests() throws {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            #if swift(>=4.0)
                let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            #else
                let darwinCount = Int(thisClass.defaultTestSuite().testCaseCount)
            #endif

            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

    static let allTests = [
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        // Console
        ("testResolveConsoleDestination", testResolveConsoleDestination),
        // File
        ("testResolveFileDestination", testResolveFileDestination),
        ("testInvalidFilePath", testInvalidFilePath),
        // SBPlatform
        ("testResolveSBPlatformDestination", testResolveSBPlatformDestination),
        ("testInvalidSBPlatformThreshold", testInvalidSBPlatformThreshold),
        ("testInvalidSBPlatformApp", testInvalidSBPlatformApp),
        ("testInvalidSBPlatformSecret", testInvalidSBPlatformSecret),
        ("testInvalidSBPlatformKey", testInvalidSBPlatformKey),
        // Others
        ("testGetMinLevel", testGetMinLevelFromJSON),
        // Commons
        ("testInvalidAsync", testInvalidAsync),
        ("testInvalidMinLevel", testInvalidMinLevel),
    ]
}