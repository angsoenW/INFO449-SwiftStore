//
//  StoreTests.swift
//  StoreTests
//
//  Created by Ted Neward on 2/29/24.
//

import XCTest

final class StoreTests: XCTestCase {

    var register = Register()

    override func setUpWithError() throws {
        register = Register()
    }

    override func tearDownWithError() throws { }

    func testBaseline() throws {
        XCTAssertEqual("0.1", Store().version)
        XCTAssertEqual("Hello world", Store().helloWorld())
    }
    
    func testOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(199, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
------------------
TOTAL: $1.99
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testThreeSameItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 3, register.subtotal())
    }
    
    func testThreeDifferentItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        register.scan(Item(name: "Pencil", priceEach: 99))
        XCTAssertEqual(298, register.subtotal())
        register.scan(Item(name: "Granols Bars (Box, 8ct)", priceEach: 499))
        XCTAssertEqual(797, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(797, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
Pencil: $0.99
Granols Bars (Box, 8ct): $4.99
------------------
TOTAL: $7.97
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testAddSingleItemSubtotal() throws {
        // Create an item, e.g., a can of beans priced at $1.99 (199 pennies)
        let item = Item(name: "Beans (8oz Can)", priceEach: 199)
        
        // Scan the item by adding it to the register
        register.scan(item)
        
        // Fetch the subtotal from the register, which should equal the item's price
        let subtotal = register.subtotal()
        
        // Assert that the subtotal is correctly calculated as the price of the single scanned item
        XCTAssertEqual(subtotal, 199, "Subtotal should be equal to the price of the single item scanned")
    }
    
    func testLessThanDiscountRequirement() throws {
        let twoForOneScheme = TwoForOnePricingScheme(validItemName: "Beans (8oz Can)")
        register.applyPricingScheme(twoForOneScheme)
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        // Only two beans scanned, discount should not apply
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), 398, "Subtotal should be without discount for two cans")
    }
    
    func testExactDiscountRequirement() throws {
        let twoForOneScheme = TwoForOnePricingScheme(validItemName: "Beans (8oz Can)")
        register.applyPricingScheme(twoForOneScheme)
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        // Three beans scanned, discount should apply
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), 398, "Subtotal should reflect two-for-one pricing")
    }
    
    func testMoreThanDiscountRequirement() throws {
        let twoForOneScheme = TwoForOnePricingScheme(validItemName: "Beans (8oz Can)")
        register.applyPricingScheme(twoForOneScheme)
        for _ in 1...5 { // Scan five cans of beans
            register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        }
        // Should apply one discount (two sets of three, but only five scanned in total)
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), 199 * 4, "Subtotal should reflect pricing for four cans due to one free can")
    }
    
    func testMixedItemDiscountApplication() throws {
        let twoForOneScheme = TwoForOnePricingScheme(validItemName: "Beans (8oz Can)")
        register.applyPricingScheme(twoForOneScheme)
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Pencil", priceEach: 50)) // Non-eligible item
        // Total should be for two beans plus one free and one pencil
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), 398 + 50, "Subtotal should reflect two-for-one pricing plus non-discounted item")
    }
    
    func testGroupedDiscountAppliedCorrectly() throws {
        let discountScheme = GroupedPricingScheme(validItemName: (item1: "Ketchup", item2: "Mustard"))
        register.applyPricingScheme(discountScheme)

        register.scan(Item(name: "Ketchup", priceEach: 300)) // $3.00
        register.scan(Item(name: "Mustard", priceEach: 200)) // $2.00
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), Int(300 * 0.90) + Int(200 * 0.90), "Subtotal should reflect grouped pricing discount")
    }

    func testWeightedItems() throws {
        let steak = WeightedItem(name: "Steak", pricePerPound: 8.99, weight: 1.1)
        register.scan(steak)
        XCTAssertEqual(register.subtotal(), 988, "Subtotal should correctly calculate the price based on weight")

        let apples = WeightedItem(name: "Apples", pricePerPound: 2.99, weight: 0.75)
        register.scan(apples)
        let receipt = register.total()
        XCTAssertEqual(receipt.total(), 988 + 224, "Subtotal should include the combined price of steak and apples by weight")
    }

}
