//
//  AutoLauncherTests.swift
//  Calendr
//
//  Created by Paker on 31/05/2026.
//

import XCTest
@testable import Calendr

class AutoLauncherTests: XCTestCase {

    let loginItem = MockLaunchService()
    let launchAgent = MockLaunchService()

    lazy var launchServices = MockLaunchServiceProvider(
        loginItem: loginItem,
        launchAgent: launchAgent
    )

    let localStorage = MockLocalStorageProvider()

    func testInit_withLoginItemDisabled() {

        loginItem.spyRegister = {
            XCTExpectFailure()
        }

        loginItem.spyUnregister = {
            XCTExpectFailure()
        }

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLoginItemEnabled)
    }

    func testInit_withLoginItemEnabled() {

        loginItem.spyRegister = {
            XCTExpectFailure()
        }

        loginItem.spyUnregister = {
            XCTExpectFailure()
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLoginItemEnabled)
    }

    func testInit_withLaunchAgentDisabled_withStorageDisabled() {

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertFalse(localStorage.launchAgentEnabled)
    }

    func testInit_withLaunchAgentEnabled_withStorageEnabled() {

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)
    }

    func testInit_withLaunchAgentDisabled_withStorageEnabled_shouldRegister() {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testInit_withLaunchAgentDisabled_withStorageEnabled_withRegisterFailure_shouldNotRollbackStorage() {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(localStorage.launchAgentEnabled)
        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testInit_withLaunchAgentEnabled_withStorageDisabled_shouldUnregister() {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = { [launchAgent] in
            launchAgent.isEnabled = false
            unregisterExpectation.fulfill()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(localStorage.launchAgentEnabled)
        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testInit_withLaunchAgentEnabled_withStorageDisabled_withUnregisterFailure_shouldUpdateLocalStorage() {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(localStorage.launchAgentEnabled)
        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testLoginItemToggleOn() {

        let registerExpectation = expectation(description: "Register")

        loginItem.spyRegister = { [loginItem] in
            loginItem.isEnabled = true
            registerExpectation.fulfill()
        }

        loginItem.spyUnregister = {
            XCTExpectFailure()
        }

        loginItem.isEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        XCTAssertTrue(autoLauncher.isLoginItemEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testLoginItemToggleOn_withRegisterFailure() {

        let registerExpectation = expectation(description: "Register")

        loginItem.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        loginItem.spyUnregister = {
            XCTExpectFailure()
        }

        loginItem.isEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        XCTAssertFalse(autoLauncher.isLoginItemEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testLoginItemToggleOff() {

        let unregisterExpectation = expectation(description: "Unregister")

        loginItem.spyRegister = {
            XCTExpectFailure()
        }

        loginItem.spyUnregister = { [loginItem] in
            loginItem.isEnabled = false
            unregisterExpectation.fulfill()
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        XCTAssertFalse(autoLauncher.isLoginItemEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testLoginItemToggleOff_withFailure() {

        let unregisterExpectation = expectation(description: "Unregister")

        loginItem.spyRegister = {
            XCTExpectFailure()
        }

        loginItem.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        XCTAssertTrue(autoLauncher.isLoginItemEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOn_withStorageDisabled() {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertFalse(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOn_withStorageDisabled_withRegisterFailure() {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertFalse(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertFalse(localStorage.launchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOff_withStorageEnabled() {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = { [launchAgent] in
            launchAgent.isEnabled = false
            unregisterExpectation.fulfill()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertFalse(localStorage.launchAgentEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOff_withStorageEnabled_withUnregisterFailure() {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            XCTExpectFailure()
        }

        launchAgent.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        wait(for: [unregisterExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOn_withStorageEnabled_withRegisterFailure_shouldNotRollbackStorage() {

        let registerExpectation = expectation(description: "Register")
        registerExpectation.expectedFulfillmentCount = 2

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        // will fail to register on init and leave storage != agent
        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        // will fail again, should not rollback storage
        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }

    func testLaunchAgentToggleOn_withStorageEnabled_withRegisterFailureOnInit_withRegisterSuccessOnToggle() {

        let registerExpectation = expectation(description: "Register")
        registerExpectation.expectedFulfillmentCount = 2

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            XCTExpectFailure()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        // will fail to register on init and leave storage != agent
        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        XCTAssertFalse(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        // success on toggle, now we can update the storage
        autoLauncher.isLaunchAgentEnabled.toggle()

        XCTAssertTrue(autoLauncher.isLaunchAgentEnabled)
        XCTAssertTrue(localStorage.launchAgentEnabled)

        wait(for: [registerExpectation], timeout: 0.1)
    }
}
