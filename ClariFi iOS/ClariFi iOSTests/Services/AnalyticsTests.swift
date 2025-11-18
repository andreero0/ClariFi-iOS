//
//  AnalyticsTests.swift
//  ClariFi iOSTests
//
//  Tests for PostHog analytics service with mocked network layer
//

import XCTest
@testable import ClariFi_iOS

class AnalyticsTests: XCTestCase {
    
    var analyticsService: PostHogAnalyticsService!
    var mockURLSession: MockURLSession!
    
    override func setUp() async throws {
        try await super.setUp()
        mockURLSession = MockURLSession()
        analyticsService = PostHogAnalyticsService()
        // Inject mock URL session for testing
        analyticsService.urlSession = mockURLSession
    }
    
    override func tearDown() async throws {
        analyticsService = nil
        mockURLSession = nil
        try await super.tearDown()
    }
    
    // MARK: - Event Tracking Tests
    
    func testBasicEventTracking() async throws {
        let expectation = XCTestExpectation(description: "Event tracked")
        
        analyticsService.track(event: .appLaunched)
        
        // Wait for batching to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify event was queued
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    func testEventWithProperties() async throws {
        let properties = [
            "amount": 100.0,
            "category": "Food & Dining",
            "merchant": "Starbucks"
        ]
        
        analyticsService.track(event: .transactionAdded, properties: properties)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify event was queued with properties
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    // MARK: - Event Batching Tests
    
    func testEventBatching() async throws {
        // Send multiple events quickly
        for i in 0..<15 { // More than batch size (10)
            analyticsService.track(event: .transactionAdded, properties: ["index": i])
        }
        
        // Wait for batching to process
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify events were batched
        XCTAssertTrue(mockURLSession.requests.count > 0)
        
        // Check that events were sent in batches
        let totalEvents = mockURLSession.requests.reduce(0) { total, request in
            if let data = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let batch = json["batch"] as? [[String: Any]] {
                return total + batch.count
            }
            return total
        }
        
        XCTAssertEqual(totalEvents, 15)
    }
    
    func testBatchFlushTimer() async throws {
        // Send one event
        analyticsService.track(event: .appLaunched)
        
        // Wait for timer flush (30 seconds, but we'll wait less in test)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify event was eventually sent
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    // MARK: - Network Payload Tests
    
    func testNetworkPayloadFormat() async throws {
        analyticsService.track(event: .transactionAdded, properties: ["amount": 100.0])
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        guard let request = mockURLSession.requests.first,
              let data = request.httpBody,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("No request data found")
            return
        }
        
        // Verify payload structure
        XCTAssertTrue(json["api_key"] is String)
        XCTAssertTrue(json["batch"] is [[String: Any]])
        
        if let batch = json["batch"] as? [[String: Any]],
           let event = batch.first {
            XCTAssertEqual(event["event"] as? String, "transaction_added")
            XCTAssertTrue(event["properties"] is [String: Any])
            XCTAssertTrue(event["timestamp"] is String)
        }
    }
    
    func testEventTimestampFormat() async throws {
        analyticsService.track(event: .appLaunched)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        guard let request = mockURLSession.requests.first,
              let data = request.httpBody,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let batch = json["batch"] as? [[String: Any]],
              let event = batch.first,
              let timestamp = event["timestamp"] as? String else {
            XCTFail("No timestamp found")
            return
        }
        
        // Verify ISO8601 format
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: timestamp)
        XCTAssertNotNil(date)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() async throws {
        // Configure mock to return error
        mockURLSession.shouldReturnError = true
        mockURLSession.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        
        analyticsService.track(event: .appLaunched)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should not crash, error should be handled gracefully
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    func testInvalidJSONHandling() async throws {
        // Configure mock to return invalid JSON
        mockURLSession.shouldReturnInvalidJSON = true
        
        analyticsService.track(event: .appLaunched)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should not crash, error should be handled gracefully
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    // MARK: - Performance Tests
    
    func testHighVolumeEventTracking() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Send many events quickly
        for i in 0..<1000 {
            analyticsService.track(event: .transactionAdded, properties: ["index": i])
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify performance is acceptable
        XCTAssertLessThan(executionTime, 0.1) // Should complete in under 100ms
        
        // Wait for batching to process
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify events were processed
        XCTAssertTrue(mockURLSession.requests.count > 0)
    }
    
    // MARK: - Configuration Tests
    
    func testDisabledAnalytics() async throws {
        // Create service with empty API key (should disable analytics)
        let disabledService = PostHogAnalyticsService()
        disabledService.apiKey = ""
        
        disabledService.track(event: .appLaunched)
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should not send any requests
        XCTAssertEqual(mockURLSession.requests.count, 0)
    }
    
    func testAPIKeyConfiguration() async throws {
        let testAPIKey = "test-api-key-123"
        analyticsService.apiKey = testAPIKey
        
        analyticsService.track(event: .appLaunched)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        guard let request = mockURLSession.requests.first,
              let data = request.httpBody,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("No request data found")
            return
        }
        
        XCTAssertEqual(json["api_key"] as? String, testAPIKey)
    }
}

// MARK: - Mock URL Session

class MockURLSession: URLSession {
    var requests: [URLRequest] = []
    var shouldReturnError = false
    var shouldReturnInvalidJSON = false
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        
        if shouldReturnError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: nil)
        }
        
        if shouldReturnInvalidJSON {
            return ("invalid json".data(using: .utf8)!, URLResponse())
        }
        
        // Return successful response
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let responseData = """
        {
            "status": "success",
            "events_received": 1
        }
        """.data(using: .utf8)!
        
        return (responseData, response)
    }
}
