//
//  OnboardingCoordinatorTests.swift
//  ClariFi iOS
//
//  Unit tests for onboarding coordinator navigation validation.
//

#if canImport(XCTest)
import XCTest
@testable import ClariFi_iOS

private final class AnalyticsStub: AnalyticsServiceProtocol {
    var isEnabled: Bool = false
    
    func initialize() {}
    func identify(userId: String, properties: [String : Any]?) {}
    func track(event: AnalyticsEvent, properties: [String : Any]?) {}
    func screen(name: String, properties: [String : Any]?) {}
    func setUserProperty(key: String, value: Any) {}
    func reset() {}
    func captureException(_ error: Error, context: [String : Any]?) {}
}

@MainActor
final class OnboardingCoordinatorTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        Analytics.setService(AnalyticsStub())
    }
    
    func testCannotAdvancePastAccountSetupWithoutAccount() {
        let coordinator = OnboardingCoordinator()
        
        coordinator.requestStepChange(to: .privacy)
        coordinator.requestStepChange(to: .features)
        coordinator.requestStepChange(to: .accountSetup)
        
        XCTAssertEqual(coordinator.currentStep, .accountSetup)
        
        coordinator.requestStepChange(to: .biometric)
        XCTAssertEqual(
            coordinator.currentStep,
            .accountSetup,
            "Coordinator should block forward progress when no accounts exist."
        )
        
        coordinator.createDefaultAccount()
        coordinator.requestStepChange(to: .biometric)
        
        XCTAssertEqual(
            coordinator.currentStep,
            .biometric,
            "Coordinator should allow progress once an account exists."
        )
    }
}

#endif
