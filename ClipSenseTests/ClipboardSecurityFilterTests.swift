//
//  ClipboardSecurityFilterTests.swift
//  ClipSenseTests
//

import Testing
@testable import ClipSense

struct ClipboardSecurityFilterTests {
    private let filter = ClipboardSecurityFilter()

    @Test func rejectsEmptyStrings() {
        #expect(filter.shouldStore("") == false)
        #expect(filter.shouldStore("   \n\t") == false)
    }

    @Test func rejectsOneTimePasscodes() {
        #expect(filter.shouldStore("123456") == false)
        #expect(filter.shouldStore("12345678") == false)
    }

    @Test func rejectsCreditCardLikeNumbersThatPassLuhn() {
        #expect(filter.shouldStore("4242 4242 4242 4242") == false)
    }

    @Test func allowsNumericTextThatDoesNotPassLuhn() {
        #expect(filter.shouldStore("4242 4242 4242 4241"))
    }

    @Test func rejectsLongRandomStrings() {
        #expect(filter.shouldStore("mN9!qW2@zX8#pL5$vB7%tR3&yU6*kE1?") == false)
    }

    @Test func allowsNormalTextAndURLs() {
        #expect(filter.shouldStore("Remember to review the menu bar clipboard UI."))
        #expect(filter.shouldStore("https://developer.apple.com/documentation/swiftdata"))
    }
}
