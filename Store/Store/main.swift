//
//  main.swift
//  Store
//
//  Created by Ted Neward on 2/29/24.
//

import Foundation

protocol SKU {
    var name: String {get}
    func price() -> Int
    
}

protocol PricingScheme {
    func getPrice(transcation: [SKU]) -> Int
}

class TwoForOnePricingScheme: PricingScheme {
    var validItemName: String
    
    init(validItemName: String) {
        self.validItemName = validItemName
    }
    
    func getPrice(transcation: [SKU]) -> Int {
        let validItems = transcation.filter( {$0.name == validItemName})
        let count = validItems.count
        if (count > 0) {
            let itemPrice = validItems[0].price()
            let qualified = count / 3
            let remainder = count % 3
            let discountedPrice = (qualified * 2 * itemPrice) + (remainder * itemPrice)
            return discountedPrice + transcation.filter( {$0.name != validItemName}).reduce(0, {$0 + $1.price()})
        }
        return transcation.reduce(0, {$0 + $1.price()})
    }
}

class GroupedPricingScheme: PricingScheme {
    var validItemName: (item1: String, item2: String)
    
    init(validItemName: (item1: String, item2: String)) {
        self.validItemName = validItemName
    }
    
    func getPrice(transcation: [SKU]) -> Int {
        var totalPrice = 0
        var itemCounts = [String: Int]()
        transcation.forEach { item in
           itemCounts[item.name, default: 0] += 1
        }

        let discountApplies = min(itemCounts[validItemName.item1] ?? 0, itemCounts[validItemName.item2] ?? 0)
        let fullPriceAppliesItem1 = (itemCounts[validItemName.item1] ?? 0) - discountApplies
        let fullPriceAppliesItem2 = (itemCounts[validItemName.item2] ?? 0) - discountApplies

        totalPrice += discountApplies * (transcation.first(where: { $0.name == validItemName.item1 })?.price() ?? 0) * Int(90) / 100
        totalPrice += discountApplies * (transcation.first(where: { $0.name == validItemName.item2 })?.price() ?? 0) * Int(90) / 100

        totalPrice += fullPriceAppliesItem1 * (transcation.first(where: { $0.name == validItemName.item1 })?.price() ?? 0)
        totalPrice += fullPriceAppliesItem2 * (transcation.first(where: { $0.name == validItemName.item2 })?.price() ?? 0)

        transcation.forEach { item in
           if item.name != validItemName.item1 && item.name != validItemName.item2 {
               totalPrice += item.price() * (itemCounts[item.name] ?? 0)
           }
        }

        return totalPrice
   }
}

class Item: SKU {
    var name: String
    var priceEach: Int
    
    init(name: String, priceEach: Int) {
        self.name = name
        self.priceEach = priceEach
    }
    
    func price() -> Int {
        return self.priceEach
    }
}

class WeightedItem: SKU {
    let itemName: String
    let pricePerPound: Double
    let weight: Double // weight in pounds

    init(name: String, pricePerPound: Double, weight: Double) {
        self.itemName = name
        self.pricePerPound = pricePerPound
        self.weight = weight
    }

    var name: String {
        return itemName
    }

    func price() -> Int {
        let totalCost = pricePerPound * weight
        return Int(totalCost * 100) // Convert to cents for consistency with the other SKU implementations
    }
}

class Receipt {
    var transcation: [SKU]
    private var pricingScheme: PricingScheme?
    
    init() {
        self.transcation = []
    }
    
    func items() -> [SKU] {
        return transcation
    }
    
    func output() -> String {
        var receiptOutput = "Receipt:\n"
        transcation.forEach { item in
            receiptOutput += "\(item.name): $\(String(Double(item.price()) / 100))\n"
        }
        receiptOutput += "------------------\n"
        receiptOutput += "TOTAL: $\(String(format: "%.2f", Double(total()) / 100))"
        return receiptOutput
    }
    
    func setPricingScheme(_ scheme: PricingScheme) {
            self.pricingScheme = scheme
    }

    func total() -> Int {
        guard let scheme = pricingScheme else {
            return transcation.reduce(0) { $0 + $1.price() }
        }
        return scheme.getPrice(transcation: transcation)
    }
}

class Register {
    var receipt: Receipt

    init() {
        self.receipt = Receipt()
    }
    
    func scan(_ item: SKU) {
        receipt.transcation.append(item)
    }
    
    func subtotal() -> Int {
        return receipt.items().reduce(0, {$0 + $1.price()})
    }
    
    func total() -> Receipt {
        let returnedReceipt = receipt
        self.receipt = Receipt()
        return returnedReceipt
    }
    
    func applyPricingScheme(_ scheme: PricingScheme) {
        receipt.setPricingScheme(scheme)
    }
}

class Store {
    let version = "0.1"
    func helloWorld() -> String {
        return "Hello world"
    }
}

