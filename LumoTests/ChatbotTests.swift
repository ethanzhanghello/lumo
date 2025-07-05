//
//  ChatbotTests.swift
//  LumoTests
//
//  Created by Assistant on 7/3/25.
//

import XCTest
@testable import Lumo

@MainActor
final class ChatbotTests: XCTestCase {
    
    var chatbotEngine: ChatbotEngine!
    var intentRecognizer: IntentRecognizer!
    var openAIService: OpenAIService!
    
    override func setUpWithError() throws {
        chatbotEngine = ChatbotEngine()
        intentRecognizer = IntentRecognizer()
        openAIService = OpenAIService()
    }
    
    override func tearDownWithError() throws {
        chatbotEngine = nil
        intentRecognizer = nil
        openAIService = nil
    }
    
    // MARK: - Debug Tests
    
    func testDebugIntentRecognition() throws {
        print("=== DEBUG INTENT RECOGNITION ===")
        
        let testQueries = [
            "Help me plan meals",
            "What can I make with my pantry?",
            "I need meal ideas",
            "Check my pantry ingredients",
            "Plan dinner for the week",
            "What are the store hours?",
            "When does the store close?",
            "Store location please",
            "What time does the store open?",
            "Where is the store?"
        ]
        
        for query in testQueries {
            print("\n🔍 Testing: '\(query)'")
            intentRecognizer.debugIntentRecognition(query: query)
            let intent = intentRecognizer.recognizeIntent(from: query)
            print("Final result: \(intent)")
        }
        
        print("=== END DEBUG ===")
    }
    
    // MARK: - Intent Recognition Tests
    
    func testRecipeIntentRecognition() throws {
        let recipeQueries = [
            "I need a recipe for pasta",
            "How to make chicken soup",
            "Can you help me cook rice?",
            "I want to prepare a salad",
            "Recipe for chocolate cake"
        ]
        
        for query in recipeQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .recipe, "Query '\(query)' should be recognized as recipe intent")
        }
    }
    
    func testProductSearchIntentRecognition() throws {
        let productQueries = [
            "Where can I find milk?",
            "Find bread in the store",
            "Which aisle is the pasta in?",
            "I need to locate tomatoes",
            "Where are the eggs located?"
        ]
        
        for query in productQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .productSearch, "Query '\(query)' should be recognized as product search intent")
        }
    }
    
    func testDealSearchIntentRecognition() throws {
        let dealQueries = [
            "Are there any deals on meat?",
            "Show me sales this week",
            "Any discounts on produce?",
            "I'm looking for coupons",
            "What's on sale today?"
        ]
        
        for query in dealQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .dealSearch, "Query '\(query)' should be recognized as deal search intent")
        }
    }
    
    func testListManagementIntentRecognition() throws {
        let listQueries = [
            "Add milk to my list",
            "Show my shopping list",
            "Remove bread from list",
            "What's on my shopping list?",
            "Clear my list"
        ]
        
        for query in listQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .listManagement, "Query '\(query)' should be recognized as list management intent")
        }
    }
    
    func testMealPlanningIntentRecognition() throws {
        let mealQueries = [
            "Help me plan meals",
            "What can I make with my pantry?",
            "I need meal ideas",
            "Check my pantry ingredients",
            "Plan dinner for the week"
        ]
        
        for query in mealQueries {
            print("\n🔍 Testing meal planning query: '\(query)'")
            intentRecognizer.debugIntentRecognition(query: query)
            let intent = intentRecognizer.recognizeIntent(from: query)
            print("Result: \(intent)")
            XCTAssertEqual(intent, .mealPlanning, "Query '\(query)' should be recognized as meal planning intent")
        }
    }
    
    func testStoreInfoIntentRecognition() throws {
        let storeQueries = [
            "What are the store hours?",
            "When does the store close?",
            "Store location please",
            "What time does the store open?",
            "Where is the store?"
        ]
        
        for query in storeQueries {
            print("\n🔍 Testing store info query: '\(query)'")
            intentRecognizer.debugIntentRecognition(query: query)
            let intent = intentRecognizer.recognizeIntent(from: query)
            print("Result: \(intent)")
            XCTAssertEqual(intent, .storeInfo, "Query '\(query)' should be recognized as store info intent")
        }
    }
    
    func testDietaryFilterIntentRecognition() throws {
        let dietaryQueries = [
            "I'm vegetarian",
            "Show me vegan options",
            "I need gluten-free products",
            "Check for nut allergens",
            "I have food allergies"
        ]
        
        for query in dietaryQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .dietaryFilter, "Query '\(query)' should be recognized as dietary filter intent")
        }
    }
    
    func testGeneralIntentRecognition() throws {
        let generalQueries = [
            "Hello",
            "How are you?",
            "What can you do?",
            "Thanks for helping",
            "Goodbye"
        ]
        
        for query in generalQueries {
            let intent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(intent, .general, "Query '\(query)' should be recognized as general intent")
        }
    }
    
    // MARK: - ChatbotEngine Tests
    
    func testChatbotEngineInitialization() throws {
        XCTAssertNotNil(chatbotEngine, "ChatbotEngine should be initialized")
        XCTAssertEqual(chatbotEngine.messages.count, 0, "Initial message count should be 0")
    }
    
    func testSendMessageAddsUserMessage() async throws {
        let userMessage = "Hello, can you help me find milk?"
        
        await chatbotEngine.sendMessage(userMessage)
        
        XCTAssertEqual(chatbotEngine.messages.count, 2, "Should have user message and bot response")
        XCTAssertTrue(chatbotEngine.messages.first?.isUser == true, "First message should be from user")
        XCTAssertEqual(chatbotEngine.messages.first?.content, userMessage, "User message content should match")
    }
    
    func testSendMessageGeneratesBotResponse() async throws {
        let userMessage = "I need a recipe for pasta"
        
        await chatbotEngine.sendMessage(userMessage)
        
        XCTAssertEqual(chatbotEngine.messages.count, 2, "Should have user message and bot response")
        XCTAssertFalse(chatbotEngine.messages.last?.isUser == true, "Last message should be from bot")
        XCTAssertFalse(chatbotEngine.messages.last?.content.isEmpty == true, "Bot response should not be empty")
    }
    
    func testClearMessages() async throws {
        // Add some messages first
        await chatbotEngine.sendMessage("Hello")
        await chatbotEngine.sendMessage("How are you?")
        
        XCTAssertGreaterThan(chatbotEngine.messages.count, 0, "Should have messages before clearing")
        
        await chatbotEngine.clearMessages()
        
        XCTAssertEqual(chatbotEngine.messages.count, 0, "Messages should be cleared")
    }
    
    func testEmptyMessageHandling() async throws {
        let initialCount = chatbotEngine.messages.count
        
        await chatbotEngine.sendMessage("")
        await chatbotEngine.sendMessage("   ")
        await chatbotEngine.sendMessage("\n")
        
        XCTAssertEqual(chatbotEngine.messages.count, initialCount, "Empty messages should not be added")
    }
    
    // MARK: - Recipe Response Tests
    
    func testRecipeResponseGeneration() async throws {
        let userMessage = "I want a recipe for chicken soup"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to recipe request")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "Recipe response should not be empty")
        
        // Check if response contains recipe-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("recipe") || content.contains("ingredient") || content.contains("cook"), "Response should be recipe-related")
    }
    
    func testRecipeResponseWithActionButtons() async throws {
        let userMessage = "Show me a pasta recipe"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to recipe request")
        
        // Check if response has action buttons
        if let actionButtons = botMessage?.actionButtons {
            XCTAssertGreaterThan(actionButtons.count, 0, "Recipe response should have action buttons")
            
            // Check for expected action buttons
            let buttonTitles = actionButtons.map { $0.title.lowercased() }
            XCTAssertTrue(buttonTitles.contains { $0.contains("add") || $0.contains("list") }, "Should have add to list button")
            XCTAssertTrue(buttonTitles.contains { $0.contains("route") || $0.contains("aisle") }, "Should have route/aisle button")
        }
    }
    
    // MARK: - Product Search Tests
    
    func testProductSearchResponse() async throws {
        let userMessage = "Where can I find milk?"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to product search")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "Product search response should not be empty")
        
        // Check if response contains location-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("aisle") || content.contains("find") || content.contains("location"), "Response should be location-related")
    }
    
    func testProductSearchWithActionButtons() async throws {
        let userMessage = "Find bread for me"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to product search")
        
        if let actionButtons = botMessage?.actionButtons {
            XCTAssertGreaterThan(actionButtons.count, 0, "Product search response should have action buttons")
            
            let buttonTitles = actionButtons.map { $0.title.lowercased() }
            XCTAssertTrue(buttonTitles.contains { $0.contains("add") || $0.contains("list") }, "Should have add to list button")
            XCTAssertTrue(buttonTitles.contains { $0.contains("route") || $0.contains("navigate") }, "Should have navigation button")
        }
    }
    
    // MARK: - Deal Search Tests
    
    func testDealSearchResponse() async throws {
        let userMessage = "Are there any deals on meat?"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to deal search")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "Deal search response should not be empty")
        
        // Check if response contains deal-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("deal") || content.contains("sale") || content.contains("discount") || content.contains("offer"), "Response should be deal-related")
    }
    
    func testDealSearchWithActionButtons() async throws {
        let userMessage = "Show me today's deals"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to deal search")
        
        if let actionButtons = botMessage?.actionButtons {
            XCTAssertGreaterThan(actionButtons.count, 0, "Deal search response should have action buttons")
            
            let buttonTitles = actionButtons.map { $0.title.lowercased() }
            XCTAssertTrue(buttonTitles.contains { $0.contains("clip") || $0.contains("coupon") }, "Should have clip coupon button")
            XCTAssertTrue(buttonTitles.contains { $0.contains("view") || $0.contains("deals") }, "Should have view deals button")
        }
    }
    
    // MARK: - List Management Tests
    
    func testListManagementResponse() async throws {
        let userMessage = "Add milk to my shopping list"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to list management request")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "List management response should not be empty")
        
        // Check if response contains list-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("list") || content.contains("add") || content.contains("shopping"), "Response should be list-related")
    }
    
    // MARK: - Store Info Tests
    
    func testStoreInfoResponse() async throws {
        let userMessage = "What are the store hours?"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to store info request")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "Store info response should not be empty")
        
        // Check if response contains store-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("store") || content.contains("hours") || content.contains("address") || content.contains("phone"), "Response should be store-related")
    }
    
    // MARK: - Dietary Filter Tests
    
    func testDietaryFilterResponse() async throws {
        let userMessage = "I'm vegetarian, what can I eat?"
        
        await chatbotEngine.sendMessage(userMessage)
        
        let botMessage = chatbotEngine.messages.last
        XCTAssertNotNil(botMessage, "Bot should respond to dietary filter request")
        XCTAssertFalse(botMessage?.content.isEmpty == true, "Dietary filter response should not be empty")
        
        // Check if response contains dietary-related content
        let content = botMessage?.content.lowercased() ?? ""
        XCTAssertTrue(content.contains("vegetarian") || content.contains("dietary") || content.contains("allergen") || content.contains("restriction"), "Response should be dietary-related")
    }
    
    // MARK: - OpenAI Service Tests
    
    func testOpenAIServiceInitialization() throws {
        XCTAssertNotNil(openAIService, "OpenAIService should be initialized")
    }
    
    func testMockRecipeSuggestion() async throws {
        let query = "I need a recipe for pasta"
        let response = await openAIService.getRecipeSuggestion(for: query)
        
        XCTAssertFalse(response.isEmpty, "Recipe suggestion should not be empty")
        XCTAssertTrue(response.contains("help"), "Mock response should be helpful")
    }
    
    func testMockProductGuidance() async throws {
        let query = "Where can I find milk?"
        let response = await openAIService.getProductGuidance(for: query)
        
        XCTAssertFalse(response.isEmpty, "Product guidance should not be empty")
        XCTAssertTrue(response.contains("help"), "Mock response should be helpful")
    }
    
    func testMockGeneralResponse() async throws {
        let query = "Hello, how are you?"
        let response = await openAIService.getGeneralResponse(for: query)
        
        XCTAssertFalse(response.isEmpty, "General response should not be empty")
        XCTAssertTrue(response.contains("help"), "Mock response should be helpful")
    }
    
    // MARK: - ChatMessage Tests
    
    func testChatMessageCreation() throws {
        let message = ChatMessage(
            content: "Test message",
            isUser: true,
            actionButtons: []
        )
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertTrue(message.isUser)
        XCTAssertEqual(message.actionButtons.count, 0)
    }
    
    func testChatMessageWithActionButtons() throws {
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus"),
            ChatActionButton(title: "Find Location", action: .showAisle, icon: "location")
        ]
        
        let message = ChatMessage(
            content: "Test message with buttons",
            isUser: false,
            actionButtons: actionButtons
        )
        
        XCTAssertEqual(message.actionButtons.count, 2)
        XCTAssertEqual(message.actionButtons.first?.title, "Add to List")
        XCTAssertEqual(message.actionButtons.first?.action, .addToList)
    }
    
    // MARK: - ChatActionButton Tests
    
    func testChatActionButtonCreation() throws {
        let button = ChatActionButton(
            title: "Test Button",
            action: .addToList,
            icon: "plus",
            color: "#FF0000"
        )
        
        XCTAssertEqual(button.title, "Test Button")
        XCTAssertEqual(button.action, .addToList)
        XCTAssertEqual(button.icon, "plus")
        XCTAssertEqual(button.color, "#FF0000")
    }
    
    // MARK: - Integration Tests
    
    func testFullConversationFlow() async throws {
        // Test a complete conversation flow
        let messages = [
            "Hello, I need help with shopping",
            "I want a recipe for chicken soup",
            "Where can I find the ingredients?",
            "Are there any deals on chicken?",
            "Add everything to my shopping list"
        ]
        
        for message in messages {
            await chatbotEngine.sendMessage(message)
        }
        
        let messageCount = chatbotEngine.messages.count
        XCTAssertEqual(messageCount, messages.count * 2, "Should have user message and bot response for each message")
        
        // Verify conversation flow
        for i in stride(from: 0, to: messageCount, by: 2) {
            XCTAssertTrue(chatbotEngine.messages[i].isUser, "Even indexed messages should be from user")
            XCTAssertFalse(chatbotEngine.messages[i + 1].isUser, "Odd indexed messages should be from bot")
        }
    }
    
    func testIntentRecognitionAccuracy() throws {
        // Test that intent recognition is accurate for edge cases
        let testCases = [
            ("recipe for pasta", IntentRecognizer.Intent.recipe),
            ("where is milk", IntentRecognizer.Intent.productSearch),
            ("deals on meat", IntentRecognizer.Intent.dealSearch),
            ("add to list", IntentRecognizer.Intent.listManagement),
            ("meal planning", IntentRecognizer.Intent.mealPlanning),
            ("store hours", IntentRecognizer.Intent.storeInfo),
            ("vegetarian options", IntentRecognizer.Intent.dietaryFilter),
            ("hello there", IntentRecognizer.Intent.general)
        ]
        
        for (query, expectedIntent) in testCases {
            let actualIntent = intentRecognizer.recognizeIntent(from: query)
            XCTAssertEqual(actualIntent, expectedIntent, "Query '\(query)' should be recognized as \(expectedIntent)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testMessageProcessingPerformance() throws {
        measure {
            // Measure the performance of processing multiple messages
            let expectation = XCTestExpectation(description: "Message processing")
            
            Task {
                for i in 1...10 {
                    await chatbotEngine.sendMessage("Test message \(i)")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testIntentRecognitionPerformance() throws {
        measure {
            // Measure the performance of intent recognition
            let testQueries = [
                "recipe for pasta", "where is milk", "deals on meat",
                "add to list", "meal planning", "store hours",
                "vegetarian options", "hello there"
            ]
            
            for query in testQueries {
                _ = intentRecognizer.recognizeIntent(from: query)
            }
        }
    }
} 