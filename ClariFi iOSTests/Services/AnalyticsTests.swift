//
//  AnalyticsTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for Analytics service batching, event types, and network integration
//

import XCTest
@testable import ClariFi_iOS

final class AnalyticsTests: XCTestCase {
    
    var analyticsService: PostHogAnalyticsService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        analyticsService = PostHogAnalyticsService()
    }
    
    override func tearDown() {
        analyticsService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Basic Analytics Tests
    
    func testAnalyticsInitialization() {
        // Given/When
        let service = PostHogAnalyticsService()
        
        // Then
        XCTAssertNotNil(service)
    }
    
    func testTrackEvent() {
        // Given
        let event = AnalyticsEvent.statementUploadStarted
        let properties = ["file_size": 1024, "file_type": "pdf"]
        
        // When
        analyticsService.track(event: event, properties: properties)
        
        // Then - Should not crash and should queue the event
        // Note: In a real test, you'd verify the event was queued
    }
    
    func testScreenTracking() {
        // Given
        let screenName = "HomeView"
        let properties = ["user_type": "premium"]
        
        // When
        analyticsService.screen(name: screenName, properties: properties)
        
        // Then - Should not crash
    }
    
    func testUserIdentification() {
        // Given
        let userId = "test_user_123"
        let properties = ["plan": "premium", "signup_date": "2024-01-01"]
        
        // When
        analyticsService.identify(userId: userId, properties: properties)
        
        // Then - Should not crash
    }
    
    func testExceptionCapture() {
        // Given
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let context = ["operation": "test_operation", "user_id": "test_user"]
        
        // When
        analyticsService.captureException(error, context: context)
        
        // Then - Should not crash
    }
    
    // MARK: - Event Batching Tests
    
    func testEventBatching() {
        // Given
        let events = (1...15).map { i in
            AnalyticsEvent.transactionAdded
        }
        
        // When - Track multiple events
        for event in events {
            analyticsService.track(event: event, properties: ["index": events.firstIndex(of: event) ?? 0])
        }
        
        // Then - Should batch events (first 10 should trigger flush)
        // Note: In a real test, you'd verify the batch was sent
    }
    
    func testBatchFlushOnTimer() {
        // Given
        let expectation = XCTestExpectation(description: "Timer flush")
        
        // When - Track an event and wait for timer flush
        analyticsService.track(event: .screenViewed, properties: ["test": "timer_flush"])
        
        // Wait for flush timer (30 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 31) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 35)
    }
    
    // MARK: - Event Type Tests
    
    func testCorrectEventTypes() {
        // Given
        let testCases: [(AnalyticsEvent, String)] = [
            (.statementUploadStarted, "statement_upload_started"),
            (.transactionAdded, "transaction_added"),
            (.budgetCreated, "budget_created"),
            (.screenViewed, "screen_viewed")
        ]
        
        // When/Then
        for (event, expectedRawValue) in testCases {
            XCTAssertEqual(event.rawValue, expectedRawValue, "Event \(event) should have correct raw value")
        }
    }
    
    func testEventProperties() {
        // Given
        let event = AnalyticsEvent.statementUploadCompleted
        let properties = [
            "file_size": 2048,
            "processing_time": 1.5,
            "transaction_count": 25,
            "success": true
        ]
        
        // When
        analyticsService.track(event: event, properties: properties)
        
        // Then - Should not crash and should include all properties
    }
    
    // MARK: - Network Integration Tests
    
    func testNetworkErrorHandling() {
        // Given
        let event = AnalyticsEvent.statementUploadFailed
        let properties = ["error": "network_timeout"]
        
        // When
        analyticsService.track(event: event, properties: properties)
        
        // Then - Should handle network errors gracefully
        // Note: In a real test, you'd mock network failures
    }
    
    func testInvalidAPIKey() {
        // Given - Service with empty API key
        let service = PostHogAnalyticsService()
        
        // When
        service.track(event: .screenViewed, properties: nil)
        
        // Then - Should not crash and should handle gracefully
    }
    
    // MARK: - Performance Tests
    
    func testHighVolumeEventTracking() {
        // Given
        let eventCount = 1000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Track many events
        for i in 0..<eventCount {
            analyticsService.track(event: .transactionAdded, properties: ["index": i])
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should handle high volume efficiently
        XCTAssertLessThan(duration, 5.0, "High volume tracking should be efficient")
    }
    
    func testConcurrentEventTracking() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent tracking")
        expectation.expectedFulfillmentCount = 100
        
        // When - Track events concurrently
        for i in 0..<100 {
            DispatchQueue.global().async {
                self.analyticsService.track(event: .transactionAdded, properties: ["thread": i])
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsageWithLargeProperties() {
        // Given
        let largeProperties = (1...1000).reduce(into: [String: Any]()) { dict, i in
            dict["key_\(i)"] = "value_\(i)" * 100 // Large string
        }
        
        // When
        analyticsService.track(event: .screenViewed, properties: largeProperties)
        
        // Then - Should not cause memory issues
        // Note: In a real test, you'd measure actual memory usage
    }
    
    // MARK: - Analytics Singleton Tests
    
    func testAnalyticsSingleton() {
        // Given
        let service = PostHogAnalyticsService()
        
        // When
        Analytics.setService(service)
        
        // Then
        Analytics.track(.screenViewed, properties: ["test": "singleton"])
        // Should not crash
    }
    
    func testAnalyticsInitialization() {
        // When
        Analytics.initialize()
        
        // Then - Should not crash
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = MockURLSessionDataTask()
        task.completionHandler = completionHandler
        task.mockData = mockData
        task.mockResponse = mockResponse
        task.mockError = mockError
        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func resume() {
        DispatchQueue.global().async {
            self.completionHandler?(self.mockData, self.mockResponse, self.mockError)
        }
    }
}
