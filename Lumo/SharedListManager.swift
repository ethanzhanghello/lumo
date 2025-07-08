//
//  SharedListManager.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import Combine

class SharedListManager: ObservableObject {
    @Published var sharedLists: [SharedList] = []
    
    init() {
        loadSampleSharedLists()
    }
    
    private func loadSampleSharedLists() {
        let sampleList = SharedList(
            name: "Family Shopping",
            createdBy: "Mom",
            createdAt: Date(),
            items: [
                SharedListItem(
                    item: sampleGroceryItems[0],
                    quantity: 2,
                    addedBy: "Mom",
                    addedAt: Date(),
                    notes: "For smoothies",
                    isUrgent: false,
                    priority: .medium
                ),
                SharedListItem(
                    item: sampleGroceryItems[3],
                    quantity: 1,
                    addedBy: "Dad",
                    addedAt: Date(),
                    notes: nil,
                    isUrgent: true,
                    priority: .urgent
                )
            ],
            isActive: true,
            sharedWith: ["Dad", "Kids"]
        )
        
        sharedLists = [sampleList]
    }
    
    func createSharedList(name: String) -> SharedList {
        let newList = SharedList(
            name: name,
            createdBy: "Current User",
            createdAt: Date(),
            items: [],
            isActive: true,
            sharedWith: []
        )
        sharedLists.append(newList)
        return newList
    }
    
    func addItemToList(_ item: GroceryItem, quantity: Int = 1, to list: SharedList, notes: String? = nil) {
        if let listIndex = sharedLists.firstIndex(where: { $0.id == list.id }) {
            let newItem = SharedListItem(
                item: item,
                quantity: quantity,
                addedBy: "Current User",
                addedAt: Date(),
                notes: notes,
                isUrgent: false,
                priority: .medium
            )
            sharedLists[listIndex] = SharedList(
                name: list.name,
                createdBy: list.createdBy,
                createdAt: list.createdAt,
                items: list.items + [newItem],
                isActive: list.isActive,
                sharedWith: list.sharedWith
            )
        }
    }
    
    func getActiveLists() -> [SharedList] {
        return sharedLists.filter { $0.isActive }
    }
    
    func getUrgentItems() -> [SharedListItem] {
        return sharedLists.flatMap { $0.urgentItems }
    }
    
    func getNotifications() -> [SharedListNotification] {
        let urgentItems = getUrgentItems()
        return urgentItems.map { item in
            SharedListNotification(
                title: "Urgent Item Added",
                message: "\(item.addedBy) added \(item.item.name) to shared list",
                timestamp: item.addedAt
            )
        }
    }
}

struct SharedListNotification {
    let title: String
    let message: String
    let timestamp: Date
} 