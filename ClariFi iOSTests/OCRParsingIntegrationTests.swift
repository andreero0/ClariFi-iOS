//
//  OCRParsingIntegrationTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import UIKit
@testable import ClariFi_iOS

struct OCRParsingIntegrationTests {
    
    var ocrService: VisionOCRService!
    var parser: SmartTransactionParser!
    
    init() throws {
        
        ocrService = VisionOCRService()
        parser = SmartTransactionParser()
    }
    
    
    // MARK: - Helper Methods
    
    private func createStatementImage(with text: String, size: CGSize = CGSize(width: 600, height: 800)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Black text with banking-style formatting
            UIColor.black.setFill()
            let font = UIFont(name: "Courier", size: 12) ?? UIFont.systemFont(ofSize: 12)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 40, y: 40, width: size.width - 80, height: size.height - 80)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createRealisticBankStatement() -> String {
        return """
        FIRST NATIONAL BANK
        CHECKING ACCOUNT STATEMENT
        Account: ****1234
        Statement Period: 01/01/2024 - 01/31/2024
        
        Date        Description                     Amount
        ------------------------------------------------
        01/02/2024  DIRECT DEPOSIT PAYROLL         $2,500.00
        01/03/2024  RENT PAYMENT AUTO PAY          $1,200.00
        01/04/2024  STARBUCKS #1234                   $4.75
        01/05/2024  SHELL GAS STATION                $42.50
        01/06/2024  GROCERY MART                     $89.34
        01/07/2024  AMAZON.COM PURCHASE              $29.99
        01/08/2024  ATM WITHDRAWAL FEE                $3.00
        01/09/2024  NETFLIX SUBSCRIPTION             $15.99
        01/10/2024  UBER EATS                        $18.50
        01/11/2024  TARGET STORE #5678               $67.89
        
        Previous Balance:    $1,500.00
        Total Debits:        $1,471.96
        Total Credits:       $2,500.00
        New Balance:         $2,528.04
        """
    }
    
    private func createCreditCardStatement() -> String {
        return """
        CHASE SAPPHIRE CREDIT CARD
        Account: ****5678
        Statement Date: 01/31/2024
        
        Transaction Date  Posted Date  Description              Amount
        --------------------------------------------------------
        01/15/2024       01/16/2024   AMAZON PRIME             $12.99
        01/16/2024       01/17/2024   STARBUCKS COFFEE          $5.25
        01/17/2024       01/18/2024   UBER RIDE                $18.50
        01/18/2024       01/19/2024   WHOLE FOODS MARKET       $89.67
        01/19/2024       01/20/2024   NETFLIX MONTHLY          $15.99
        01/20/2024       01/21/2024   GAS STATION              $45.00
        01/21/2024       01/22/2024   RESTAURANT DINNER        $78.90
        01/22/2024       01/23/2024   ONLINE SHOPPING          $125.00
        
        Previous Balance:     $234.56
        New Charges:          $391.30
        Payments:             $500.00
        New Balance:          $125.86
        """
    }
    
    // MARK: - End-to-End Pipeline Tests
    
    func testCompleteOCRParsingPipeline_BankStatement() async throws {
        // Given
        let statementText = createRealisticBankStatement()
        let statementImage = createStatementImage(with: statementText)
        
        // When - OCR Processing
        let ocrResult = try await ocrService.processImage(statementImage)
        
        // Then - Verify OCR extracted text
        #expect(ocrResult.rawText.isEmpty == false)
        #expect(ocrResult.confidence > 0.5)
        
        // When - Parse transactions from OCR text
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
        
        // Then - Verify parsed transactions
        #expect(transactions.count > 5) // Should find multiple transactions
        
        // Check specific transactions
        let starbucksTransaction = transactions.first { $0.merchant?.contains("STARBUCKS") == true }
        #expect(starbucksTransaction, "Should find Starbucks transaction" != nil)
        
        let amazonTransaction = transactions.first { $0.merchant?.contains("AMAZON") == true }
        #expect(amazonTransaction, "Should find Amazon transaction" != nil)
        
        // Verify transaction details
        if let starbucks = starbucksTransaction {
            #expect(starbucks.date != nil)
            #expect(starbucks.amount != nil)
            #expect(starbucks.confidence.overall > 0.6)
        }
    }
    
    func testCompleteOCRParsingPipeline_CreditCardStatement() async throws {
        // Given
        let creditCardText = createCreditCardStatement()
        let creditCardImage = createStatementImage(with: creditCardText)
        
        // When - OCR Processing
        let ocrResult = try await ocrService.processImage(creditCardImage)
        
        // Then - Verify OCR
        #expect(ocrResult.rawText.isEmpty == false)
        #expect(ocrResult.confidence > 0.5)
        
        // When - Parse transactions
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .chase)
        
        // Then - Verify parsing
        #expect(transactions.count > 3)
        
        // Check for subscription transactions
        let netflixTransaction = transactions.first { $0.merchant?.contains("NETFLIX") == true }
        if let netflix = netflixTransaction {
            #expect(netflix.category == "Entertainment")
            #expect(netflix.amount != nil)
        }
        
        // Check for food transactions
        let wholeFoodsTransaction = transactions.first { $0.merchant?.contains("WHOLE FOODS") == true }
        if let wholefoods = wholeFoodsTransaction {
            #expect(wholefoods.category == "Groceries")
        }
    }
    
    // MARK: - Confidence Correlation Tests
    
    func testConfidenceCorrelation_OCRToParser() async throws {
        // Given - High quality statement
        let highQualityText = """
        01/15/2024  STARBUCKS STORE #1234    $4.50
        01/16/2024  SHELL GAS STATION        $35.00
        01/17/2024  GROCERY MART             $67.89
        """
        let highQualityImage = createStatementImage(with: highQualityText)
        
        // When
        let ocrResult = try await ocrService.processImage(highQualityImage)
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
        
        // Then - High OCR confidence should lead to high parsing confidence
        if ocrResult.confidence > 0.8 {
            let highConfidenceTransactions = transactions.filter { $0.confidence.overall > 0.7 }
            #expect(highConfidenceTransactions.count > 0, "High OCR confidence should produce high parsing confidence")
        }
        
        // Verify individual field confidence
        for transaction in transactions {
            if transaction.date != nil && transaction.merchant != nil && transaction.amount != nil {
                #expect(transaction.confidence.overall > 0.6, "Complete transactions should have reasonable confidence")
            }
        }
    }
    
    func testConfidenceCorrelation_LowQualityInput() async throws {
        // Given - Lower quality, smaller image
        let lowQualityText = "01/15 Store $10"
        let lowQualityImage = createStatementImage(with: lowQualityText, size: CGSize(width: 200, height: 100))
        
        // When
        do {
            let ocrResult = try await ocrService.processImage(lowQualityImage)
            let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
            
            // Then - Lower quality should result in lower confidence
            if ocrResult.confidence < 0.7 {
                let lowConfidenceTransactions = transactions.filter { $0.confidence.overall < 0.8 }
                #expect(lowConfidenceTransactions.count > 0, "Low OCR confidence should produce lower parsing confidence")
            }
            
        } catch OCRError.lowConfidence, OCRError.noTextFound {
            // These errors are acceptable for very low quality input
            #expect(true == true)
        } catch ParserError.noTransactionsFound {
            // This is also acceptable if OCR produces unusable text
            #expect(true == true)
        }
    }
    
    // MARK: - Error Propagation Tests
    
    func testErrorPropagation_OCRFailureToParser() async throws {
        // Given - Invalid image data
        let emptyImage = createStatementImage(with: "", size: CGSize(width: 100, height: 100))
        
        // When & Then
        do {
            let ocrResult = try await ocrService.processImage(emptyImage)
            
            // If OCR succeeds with empty/low confidence, parser should handle gracefully
            do {
                _ = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
                Issue.record("Parser should fail with empty OCR text")
            } catch ParserError.noTransactionsFound {
                // Expected error
                #expect(true == true)
            }
            
        } catch OCRError.noTextFound {
            // Expected OCR error
            #expect(true == true)
        }
    }
    
    func testErrorPropagation_PartialOCRSuccess() async throws {
        // Given - Image with some text but poor quality
        let partialText = "BANK STATEMENT\n01/15 Store"
        let partialImage = createStatementImage(with: partialText, size: CGSize(width: 300, height: 200))
        
        // When
        let ocrResult = try await ocrService.processImage(partialImage)
        
        // Then - OCR might succeed but with low confidence
        #expect(ocrResult.rawText.isEmpty == false)
        
        // When - Try to parse the partial text
        do {
            let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
            
            // If parsing succeeds, transactions should have low confidence
            for transaction in transactions {
                #expect(transaction.confidence.overall < 0.8, "Partial data should result in lower confidence")
            }
            
        } catch ParserError.noTransactionsFound {
            // This is acceptable for partial/poor quality text
            #expect(true == true)
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformance_CompleteOCRParsingPipeline() async throws {
        // Given
        let statementText = createRealisticBankStatement()
        let statementImage = createStatementImage(with: statementText)
        
        // When - Measure complete pipeline performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let ocrResult = try await ocrService.processImage(statementImage)
        let ocrTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let parseStartTime = CFAbsoluteTimeGetCurrent()
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStartTime
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Verify reasonable performance
        #expect(ocrTime < 10.0, "OCR should complete within 10 seconds")
        #expect(parseTime < 2.0, "Parsing should complete within 2 seconds")
        #expect(totalTime < 12.0, "Complete pipeline should finish within 12 seconds")
        
        // Verify results quality
        #expect(transactions.count > 5)
        #expect(ocrResult.confidence > 0.5)
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testRealWorldScenario_MixedQualityStatement() async throws {
        // Given - Statement with mixed quality sections
        let mixedQualityText = """
        BANK STATEMENT - JANUARY 2024
        
        Clear Section:
        01/15/2024  STARBUCKS COFFEE         $4.50
        01/16/2024  SHELL GAS STATION        $35.00
        
        Blurry Section:
        01/17  Groc Store  $67
        01/18  Amzn  $29
        
        Good Section:
        01/19/2024  NETFLIX SUBSCRIPTION     $15.99
        01/20/2024  TARGET STORE #1234       $89.34
        """
        
        let mixedImage = createStatementImage(with: mixedQualityText)
        
        // When
        let ocrResult = try await ocrService.processImage(mixedImage)
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
        
        // Then - Should handle mixed quality gracefully
        #expect(transactions.count > 3)
        
        // Check that high-quality transactions have high confidence
        let highQualityTransactions = transactions.filter { transaction in
            transaction.merchant?.contains("STARBUCKS") == true ||
            transaction.merchant?.contains("NETFLIX") == true ||
            transaction.merchant?.contains("TARGET") == true
        }
        
        for transaction in highQualityTransactions {
            #expect(transaction.confidence.overall > 0.7, "High quality sections should have high confidence")
        }
        
        // Check that low-quality transactions have lower confidence
        let lowQualityTransactions = transactions.filter { transaction in
            transaction.merchant?.contains("Groc") == true ||
            transaction.merchant?.contains("Amzn") == true
        }
        
        for transaction in lowQualityTransactions {
            #expect(transaction.confidence.overall < 0.9, "Low quality sections should have lower confidence")
        }
    }
    
    func testRealWorldScenario_StatementWithNoise() async throws {
        // Given - Statement with headers, footers, and noise
        let noisyStatementText = """
        ===============================================
        FIRST NATIONAL BANK - CONFIDENTIAL
        Customer Service: 1-800-123-4567
        ===============================================
        
        CHECKING ACCOUNT STATEMENT
        Account Number: ****1234
        Statement Period: 01/01/2024 - 01/31/2024
        
        TRANSACTION HISTORY:
        Date        Description              Amount
        ----------------------------------------
        01/15/2024  STARBUCKS #1234         $4.50
        01/16/2024  SHELL GAS STATION       $35.00
        01/17/2024  GROCERY MART            $67.89
        
        ----------------------------------------
        Previous Balance:     $1,000.00
        Total Debits:         $107.39
        Total Credits:        $0.00
        New Balance:          $892.61
        
        ===============================================
        Thank you for banking with us!
        Visit us online at www.firstnational.com
        ===============================================
        """
        
        let noisyImage = createStatementImage(with: noisyStatementText)
        
        // When
        let ocrResult = try await ocrService.processImage(noisyImage)
        let transactions = try await parser.parseTransactions(from: ocrResult.rawText, format: .generic)
        
        // Then - Should filter out noise and extract only transactions
        #expect(transactions.count == 3, "Should extract exactly 3 transactions, ignoring noise")
        
        // Verify that noise was filtered out
        let transactionTexts = transactions.map { $0.rawText.lowercased() }
        
        // Should not include header/footer text as transactions
        for transactionText in transactionTexts {
            #expect(transactionText.contains("customer service" == false))
            #expect(transactionText.contains("thank you" == false))
            #expect(transactionText.contains("previous balance" == false))
            #expect(transactionText.contains("new balance" == false))
        }
        
        // Should include actual transactions
        let merchantNames = transactions.compactMap { $0.merchant?.lowercased() }
        #expect(merchantNames.contains { $0.contains("starbucks" == true) })
        #expect(merchantNames.contains { $0.contains("shell" == true) })
        #expect(merchantNames.contains { $0.contains("grocery" == true) })
    }
}