//
//  AutoLauncherTests.swift
//  Calendr
//
//  Created by Paker on 31/05/2026.
//

import Foundation
import Testing
@testable import Calendr

class AutoLauncherTests {

    let loginItem = MockLaunchService()
    let launchAgent = MockLaunchService()

    lazy var launchServices = MockLaunchServiceProvider(
        loginItem: loginItem,
        launchAgent: launchAgent
    )

    let localStorage = MockLocalStorageProvider()

    @Test func testInit_withLoginItemDisabled() {

        loginItem.spyRegister = {
            Issue.record()
        }

        loginItem.spyUnregister = {
            Issue.record()
        }

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled == false)
    }

    @Test func testInit_withLoginItemEnabled() {

        loginItem.spyRegister = {
            Issue.record()
        }

        loginItem.spyUnregister = {
            Issue.record()
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled)
    }

    @Test func testInit_withLaunchAgentDisabled_withStorageDisabled() {

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled == false)
    }

    @Test func testInit_withLaunchAgentEnabled_withStorageEnabled() {

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)
    }

    @Test func testInit_withLaunchAgentDisabled_withStorageEnabled_shouldRegister() async {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testInit_withLaunchAgentDisabled_withStorageEnabled_withRegisterFailure_shouldNotRollbackStorage() async {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(localStorage.launchAgentEnabled)
        #expect(autoLauncher.isLaunchAgentEnabled == false)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testInit_withLaunchAgentEnabled_withStorageDisabled_shouldUnregister() async {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = { [launchAgent] in
            launchAgent.isEnabled = false
            unregisterExpectation.fulfill()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(localStorage.launchAgentEnabled == false)
        #expect(autoLauncher.isLaunchAgentEnabled == false)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testInit_withLaunchAgentEnabled_withStorageDisabled_withUnregisterFailure_shouldUpdateLocalStorage() async {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(localStorage.launchAgentEnabled)
        #expect(autoLauncher.isLaunchAgentEnabled)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testLoginItemToggleOn() async {

        let registerExpectation = expectation(description: "Register")

        loginItem.spyRegister = { [loginItem] in
            loginItem.isEnabled = true
            registerExpectation.fulfill()
        }

        loginItem.spyUnregister = {
            Issue.record()
        }

        loginItem.isEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled == false)

        autoLauncher.isLoginItemEnabled.toggle()

        #expect(autoLauncher.isLoginItemEnabled)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testLoginItemToggleOn_withRegisterFailure() async {

        let registerExpectation = expectation(description: "Register")

        loginItem.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        loginItem.spyUnregister = {
            Issue.record()
        }

        loginItem.isEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled == false)

        autoLauncher.isLoginItemEnabled.toggle()

        #expect(autoLauncher.isLoginItemEnabled == false)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testLoginItemToggleOff() async {

        let unregisterExpectation = expectation(description: "Unregister")

        loginItem.spyRegister = {
            Issue.record()
        }

        loginItem.spyUnregister = { [loginItem] in
            loginItem.isEnabled = false
            unregisterExpectation.fulfill()
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        #expect(autoLauncher.isLoginItemEnabled == false)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testLoginItemToggleOff_withFailure() async {

        let unregisterExpectation = expectation(description: "Unregister")

        loginItem.spyRegister = {
            Issue.record()
        }

        loginItem.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        loginItem.isEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLoginItemEnabled)

        autoLauncher.isLoginItemEnabled.toggle()

        #expect(autoLauncher.isLoginItemEnabled)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testLaunchAgentToggleOn_withStorageDisabled() async {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled == false)

        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testLaunchAgentToggleOn_withStorageDisabled_withRegisterFailure() async {

        let registerExpectation = expectation(description: "Register")

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = false

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled == false)

        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled == false)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testLaunchAgentToggleOff_withStorageEnabled() async {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = { [launchAgent] in
            launchAgent.isEnabled = false
            unregisterExpectation.fulfill()
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled == false)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testLaunchAgentToggleOff_withStorageEnabled_withUnregisterFailure() async {

        let unregisterExpectation = expectation(description: "Unregister")

        launchAgent.spyRegister = {
            Issue.record()
        }

        launchAgent.spyUnregister = {
            unregisterExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.isEnabled = true
        localStorage.launchAgentEnabled = true

        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        await fulfillment(of: [unregisterExpectation])
    }

    @Test func testLaunchAgentToggleOn_withStorageEnabled_withRegisterFailure_shouldNotRollbackStorage() async {

        let registerExpectation = expectation(description: "Register")
        registerExpectation.expectedFulfillmentCount = 2

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        // will fail to register on init and leave storage != agent
        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled)

        // will fail again, should not rollback storage
        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled)

        await fulfillment(of: [registerExpectation])
    }

    @Test func testLaunchAgentToggleOn_withStorageEnabled_withRegisterFailureOnInit_withRegisterSuccessOnToggle() async {

        let registerExpectation = expectation(description: "Register")
        registerExpectation.expectedFulfillmentCount = 2

        launchAgent.spyRegister = {
            registerExpectation.fulfill()
            throw .unexpected("failed")
        }

        launchAgent.spyUnregister = {
            Issue.record()
        }

        launchAgent.isEnabled = false
        localStorage.launchAgentEnabled = true

        // will fail to register on init and leave storage != agent
        let autoLauncher = AutoLauncher(launchServices: launchServices, localStorage: localStorage)

        #expect(autoLauncher.isLaunchAgentEnabled == false)
        #expect(localStorage.launchAgentEnabled)

        launchAgent.spyRegister = { [launchAgent] in
            launchAgent.isEnabled = true
            registerExpectation.fulfill()
        }

        // success on toggle, now we can update the storage
        autoLauncher.isLaunchAgentEnabled.toggle()

        #expect(autoLauncher.isLaunchAgentEnabled)
        #expect(localStorage.launchAgentEnabled)

        await fulfillment(of: [registerExpectation])
    }
}
