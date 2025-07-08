//
//  ChatbotTests.swift
//  LumoTests
//
//  Created by Assistant on 7/3/25.
//

import XCTest
import SwiftUI
@testable import Lumo

@MainActor
final class ChatbotTests: XCTestCase {
    
    var chatbotEngine: ChatbotEngine!
    var intentRecognizer: IntentRecognizer!
    var openAIService: OpenAIService!
    var appState: AppState!

    override func setUpWithError() throws {
        appState = AppState()
        chatbotEngine = ChatbotEngine(appState: appState)
        intentRecognizer = IntentRecognizer()
        openAIService = OpenAIService()
    }

    override func tearDownWithError() throws {
        chatbotEngine = nil
        intentRecognizer = nil
        openAIService = nil
        appState = nil
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
        
        chatbotEngine.clearMessages()
        
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
    
    // MARK: - Comprehensive Chatbot Button Tests
    
    func testPantryManagementButtons() async throws {
        // Test all pantry management action buttons
        let pantryActions: [ChatAction] = [.showPantry, .scanBarcode, .removeExpired, .addToPantry, .pantryCheck]
        
        for action in pantryActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    func testSharedListButtons() async throws {
        // Test all shared list action buttons
        let sharedListActions: [ChatAction] = [.showSharedLists, .addToSharedList, .showUrgent, .shareList, .showFamily, .syncStatus]
        
        for action in sharedListActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    func testBudgetOptimizationButtons() async throws {
        // Test all budget optimization action buttons
        let budgetActions: [ChatAction] = [.showBudget, .optimizeBudget, .budgetFilter, .comparePrices]
        
        for action in budgetActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    func testSmartSuggestionButtons() async throws {
        // Test all smart suggestion action buttons
        let suggestionActions: [ChatAction] = [.showSeasonal, .showFrequent, .showWeather, .showHoliday, .addAllSuggestions]
        
        for action in suggestionActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    func testNavigationButtons() async throws {
        // Test all navigation action buttons
        let navigationActions: [ChatAction] = [.navigateTo, .showAisle, .findInStore, .storeInfo]
        
        for action in navigationActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    func testFilterButtons() async throws {
        // Test all filter action buttons
        let filterActions: [ChatAction] = [.filterByDiet, .budgetFilter, .timeFilter, .allergenCheck]
        
        for action in filterActions {
            XCTAssertNotNil(action.rawValue, "Action \(action) should have a valid raw value")
        }
    }
    
    // MARK: - Comprehensive FlyToCart Animation Tests
    
    func testFlyToCartAnimationManagerInitialization() throws {
        let manager = FlyToCartAnimationManager()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isAnimating)
        XCTAssertFalse(manager.cartPulse)
        XCTAssertNil(manager.currentRequest)
    }
    
    func testFlyToCartAnimationCompletion() throws {
        let manager = FlyToCartAnimationManager()
        let dummyImage = Image(systemName: "cart")
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 100, y: 100)
        
        manager.trigger(image: dummyImage, start: start, end: end)
        XCTAssertTrue(manager.isAnimating)
        
        manager.complete()
        
        XCTAssertFalse(manager.isAnimating)
        XCTAssertNil(manager.currentRequest)
        XCTAssertTrue(manager.cartPulse)
        
        // Wait for pulse to reset
        let expectation = XCTestExpectation(description: "Cart pulse reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertFalse(manager.cartPulse)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFlyToCartAnimationMultipleTriggers() throws {
        let manager = FlyToCartAnimationManager()
        
        let dummyImage = Image(systemName: "cart")
        let start1 = CGPoint(x: 0, y: 0)
        let end1 = CGPoint(x: 100, y: 100)
        let start2 = CGPoint(x: 50, y: 50)
        let end2 = CGPoint(x: 150, y: 150)
        
        // First trigger
        manager.trigger(image: dummyImage, start: start1, end: end1)
        XCTAssertTrue(manager.isAnimating)
        XCTAssertEqual(manager.currentRequest?.start, start1)
        
        // Second trigger should override first
        manager.trigger(image: dummyImage, start: start2, end: end2)
        XCTAssertTrue(manager.isAnimating)
        XCTAssertEqual(manager.currentRequest?.start, start2)
        
        manager.complete()
        XCTAssertFalse(manager.isAnimating)
    }
    
    func testFlyToCartAnimationRequestProperties() throws {
        let manager = FlyToCartAnimationManager()
        let dummyImage = Image(systemName: "cart")
        let start = CGPoint(x: 10, y: 20)
        let end = CGPoint(x: 100, y: 200)
        
        manager.trigger(image: dummyImage, start: start, end: end)
        
        guard let request = manager.currentRequest else {
            XCTFail("Animation request should not be nil")
            return
        }
        
        XCTAssertEqual(request.start, start)
        XCTAssertEqual(request.end, end)
        XCTAssertNotNil(request.id)
    }
    
    // MARK: - Chatbot Engine Integration Tests
    
    func testChatbotEngineWithAllActionTypes() async throws {
        // Test that chatbot engine can handle all action types without crashing
        let testMessages = [
            "I need a recipe for pasta",
            "Where can I find milk?",
            "Show me deals on meat",
            "Add bread to my list",
            "Help me plan meals",
            "What are the store hours?",
            "I'm vegetarian",
            "Check my pantry",
            "Show shared lists",
            "Optimize my budget",
            "Show seasonal items"
        ]
        
        for message in testMessages {
            await chatbotEngine.sendMessage(message)
            // Just verify no crash, don't check specific responses
            XCTAssertGreaterThan(chatbotEngine.messages.count, 0)
        }
    }
    
    func testChatActionButtonCreation() throws {
        // Test that all ChatActionButton instances can be created without issues
        let allActions = ChatAction.allCases
        
        for action in allActions {
            let button = ChatActionButton(
                title: "Test \(action.rawValue)",
                action: action,
                icon: "star"
            )
            
            XCTAssertNotNil(button)
            XCTAssertEqual(button.action, action)
            XCTAssertNotNil(button.id)
        }
    }
    

} 