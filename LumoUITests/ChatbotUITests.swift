//
//  ChatbotUITests.swift
//  LumoUITests
//
//  Created by Assistant on 7/3/25.
//

import XCTest

final class ChatbotUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testChatbotTabNavigation() throws {
        // Navigate to chatbot tab
        let chatbotTab = app.tabBars.buttons["AI Assistant"]
        XCTAssertTrue(chatbotTab.exists, "Chatbot tab should exist")
        chatbotTab.tap()
        
        // Verify we're on the chatbot screen
        let navigationTitle = app.navigationBars.staticTexts["AI Assistant"]
        XCTAssertTrue(navigationTitle.exists, "Should be on AI Assistant screen")
    }
    
    func testChatbotTabAccessibility() throws {
        // Test that chatbot tab is accessible
        let chatbotTab = app.tabBars.buttons["AI Assistant"]
        XCTAssertTrue(chatbotTab.isAccessibilityElement, "Chatbot tab should be accessible")
        XCTAssertNotNil(chatbotTab.accessibilityLabel, "Chatbot tab should have accessibility label")
    }
    
    // MARK: - Welcome Message Tests
    
    func testWelcomeMessageDisplay() throws {
        // Navigate to chatbot
        app.tabBars.buttons["AI Assistant"].tap()
        
        // Check for welcome message
        let welcomeText = app.staticTexts.containing(.init(format: "Lumo AI Assistant")).firstMatch
        XCTAssertTrue(welcomeText.exists, "Welcome message should be displayed")
        
        // Check for feature descriptions
        let recipeText = app.staticTexts.containing(.init(format: "Recipe Guidance")).firstMatch
        XCTAssertTrue(recipeText.exists, "Recipe guidance should be mentioned")
        
        let productText = app.staticTexts.containing(.init(format: "Product Finder")).firstMatch
        XCTAssertTrue(productText.exists, "Product finder should be mentioned")
        
        let dealsText = app.staticTexts.containing(.init(format: "Deals & Coupons")).firstMatch
        XCTAssertTrue(dealsText.exists, "Deals & coupons should be mentioned")
    }
    
    // MARK: - Input Field Tests
    
    func testInputFieldExists() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        XCTAssertTrue(inputField.exists, "Input field should exist")
        XCTAssertTrue(inputField.isEnabled, "Input field should be enabled")
    }
    
    func testInputFieldPlaceholder() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        XCTAssertEqual(inputField.placeholderValue, "Ask me anything...", "Input field should have correct placeholder")
    }
    
    func testInputFieldTyping() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        inputField.typeText("Hello, can you help me?")
        
        XCTAssertEqual(inputField.value as? String, "Hello, can you help me?", "Input field should accept text")
    }
    
    func testInputFieldClear() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        inputField.typeText("Test message")
        
        // Clear the field
        inputField.doubleTap()
        inputField.typeText("")
        
        XCTAssertEqual(inputField.value as? String, "", "Input field should be clearable")
    }
    
    // MARK: - Send Button Tests
    
    func testSendButtonExists() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let sendButton = app.buttons["arrow.up.circle.fill"]
        XCTAssertTrue(sendButton.exists, "Send button should exist")
    }
    
    func testSendButtonDisabledWhenEmpty() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let sendButton = app.buttons["arrow.up.circle.fill"]
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled when input is empty")
    }
    
    func testSendButtonEnabledWhenTyping() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        inputField.tap()
        inputField.typeText("Hello")
        
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled when typing")
    }
    
    func testSendButtonTap() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        inputField.tap()
        inputField.typeText("Hello")
        sendButton.tap()
        
        // Verify message was sent (input field should be cleared)
        XCTAssertEqual(inputField.value as? String, "", "Input field should be cleared after sending")
    }
    
    // MARK: - Message Display Tests
    
    func testUserMessageDisplay() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        inputField.tap()
        inputField.typeText("Test user message")
        sendButton.tap()
        
        // Check if user message is displayed
        let userMessage = app.staticTexts["Test user message"]
        XCTAssertTrue(userMessage.exists, "User message should be displayed")
    }
    
    func testBotResponseDisplay() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        inputField.tap()
        inputField.typeText("Hello")
        sendButton.tap()
        
        // Wait for bot response
        let expectation = XCTestExpectation(description: "Bot response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Check if bot response is displayed (should not be the same as user message)
        let userMessage = app.staticTexts["Hello"]
        let botResponses = app.staticTexts.allElementsBoundByIndex.filter { !$0.label.isEmpty && $0.label != "Hello" }
        
        XCTAssertGreaterThan(botResponses.count, 0, "Bot should respond with a message")
    }
    
    // MARK: - Toolbar Tests
    
    func testToolbarButtonsExist() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let doneButton = app.navigationBars.buttons["Done"]
        let clearButton = app.navigationBars.buttons["Clear"]
        
        XCTAssertTrue(doneButton.exists, "Done button should exist in toolbar")
        XCTAssertTrue(clearButton.exists, "Clear button should exist in toolbar")
    }
    
    func testDoneButtonTap() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let doneButton = app.navigationBars.buttons["Done"]
        doneButton.tap()
        
        // Should return to main tab view
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Should return to main tab view")
    }
    
    func testClearButtonTap() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        // Send a message first
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        inputField.tap()
        inputField.typeText("Test message")
        sendButton.tap()
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Bot response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Clear messages
        let clearButton = app.navigationBars.buttons["Clear"]
        clearButton.tap()
        
        // Check if messages are cleared (welcome message should still be there)
        let welcomeText = app.staticTexts.containing(.init(format: "Lumo AI Assistant")).firstMatch
        XCTAssertTrue(welcomeText.exists, "Welcome message should remain after clearing")
        
        let userMessage = app.staticTexts["Test message"]
        XCTAssertFalse(userMessage.exists, "User message should be cleared")
    }
    
    // MARK: - Keyboard Tests
    
    func testKeyboardAppearsOnInputTap() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        
        // Check if keyboard appears
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.exists, "Keyboard should appear when tapping input field")
    }
    
    func testKeyboardDismissal() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        
        // Type something
        inputField.typeText("Test")
        
        // Tap outside to dismiss keyboard
        app.tap()
        
        // Check if keyboard is dismissed
        let keyboard = app.keyboards.firstMatch
        XCTAssertFalse(keyboard.exists, "Keyboard should be dismissed when tapping outside")
    }
    
    // MARK: - Accessibility Tests
    
    func testChatbotAccessibility() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        // Test accessibility for main elements
        let inputField = app.textFields["Ask me anything..."]
        XCTAssertTrue(inputField.isAccessibilityElement, "Input field should be accessible")
        
        let sendButton = app.buttons["arrow.up.circle.fill"]
        XCTAssertTrue(sendButton.isAccessibilityElement, "Send button should be accessible")
        
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.isAccessibilityElement, "Done button should be accessible")
        
        let clearButton = app.navigationBars.buttons["Clear"]
        XCTAssertTrue(clearButton.isAccessibilityElement, "Clear button should be accessible")
    }
    
    // MARK: - Performance Tests
    
    func testChatbotLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.tabBars.buttons["AI Assistant"].tap()
        }
    }
    
    func testMessageSendingPerformance() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        measure {
            inputField.tap()
            inputField.typeText("Performance test message")
            sendButton.tap()
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testLongMessageInput() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        
        // Type a very long message
        let longMessage = String(repeating: "This is a very long message to test input handling. ", count: 10)
        inputField.typeText(longMessage)
        
        XCTAssertEqual(inputField.value as? String, longMessage, "Input field should handle long messages")
    }
    
    func testSpecialCharactersInput() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        
        // Type special characters
        let specialMessage = "Hello! How are you? I need help with recipes, deals, and finding products. 123 @#$%"
        inputField.typeText(specialMessage)
        
        XCTAssertEqual(inputField.value as? String, specialMessage, "Input field should handle special characters")
    }
    
    func testEmptyMessageSending() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        // Try to send empty message
        inputField.tap()
        sendButton.tap()
        
        // Should not send empty message
        XCTAssertFalse(sendButton.isEnabled, "Send button should remain disabled for empty message")
    }
    
    func testWhitespaceOnlyMessage() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        // Try to send whitespace-only message
        inputField.tap()
        inputField.typeText("   ")
        sendButton.tap()
        
        // Should not send whitespace-only message
        XCTAssertFalse(sendButton.isEnabled, "Send button should remain disabled for whitespace-only message")
    }
    
    // MARK: - Integration Tests
    
    func testFullConversationFlow() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        let inputField = app.textFields["Ask me anything..."]
        let sendButton = app.buttons["arrow.up.circle.fill"]
        
        // Test multiple message exchanges
        let messages = [
            "Hello, I need help with shopping",
            "I want a recipe for pasta",
            "Where can I find the ingredients?",
            "Are there any deals on meat?"
        ]
        
        for message in messages {
            inputField.tap()
            inputField.typeText(message)
            sendButton.tap()
            
            // Wait for response
            let expectation = XCTestExpectation(description: "Bot response for: \(message)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
        
        // Verify all messages were sent
        for message in messages {
            let messageElement = app.staticTexts[message]
            XCTAssertTrue(messageElement.exists, "Message '\(message)' should be displayed")
        }
    }
    
    func testTabSwitchingWithActiveChat() throws {
        app.tabBars.buttons["AI Assistant"].tap()
        
        // Start typing a message
        let inputField = app.textFields["Ask me anything..."]
        inputField.tap()
        inputField.typeText("Incomplete message")
        
        // Switch to another tab
        app.tabBars.buttons["Browse"].tap()
        
        // Switch back to chatbot
        app.tabBars.buttons["AI Assistant"].tap()
        
        // Verify input field still has the text
        XCTAssertEqual(inputField.value as? String, "Incomplete message", "Input field should retain text when switching tabs")
    }
} 