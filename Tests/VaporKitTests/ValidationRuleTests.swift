import XCTest
@testable import VaporKit

final class ValidationRuleTests: XCTestCase {
    func testNamedRulesPreserveStableDescriptions() {
        XCTAssertEqual(ValidationRule.email.description, ".email")
        XCTAssertEqual(ValidationRule.ascii.description, ".ascii")
        XCTAssertEqual(ValidationRule.url.description, ".url")
        XCTAssertEqual(ValidationRule.nil.description, ".nil")
    }

    func testArgumentRulesPreserveStableDescriptions() {
        XCTAssertEqual(ValidationRule.count(3...).description, ".count(3...)")
        XCTAssertEqual(ValidationRule.range(18...).description, ".range(18...)")
        XCTAssertEqual(ValidationRule.range(18...65).description, ".range(18...65)")
        XCTAssertEqual(ValidationRule.range(18..<65).description, ".range(18..<65)")
        XCTAssertEqual(ValidationRule.count(...32).description, ".count(...32)")
        XCTAssertEqual(ValidationRule.count(..<32).description, ".count(..<32)")
        XCTAssertEqual(ValidationRule.in("owner", "maintainer").description, #".in("owner", "maintainer")"#)
        XCTAssertEqual(ValidationRule.in(1, 2, 3).description, ".in(1, 2, 3)")
        XCTAssertEqual(
            ValidationRule.characterSet(.decimalDigits).description,
            ".characterSet(<CFCharacterSet Predefined DecimalDigit Set>)"
        )
    }

    func testCompositeRulesBuildAnActualRuleTree() {
        let rule = !ValidationRule.empty && (.ascii || .alphanumeric)

        XCTAssertEqual(rule.description, "!.empty && (.ascii || .alphanumeric)")
        XCTAssertEqual(
            rule,
            .init(
                kind: .and(
                    .init(kind: .not(.empty)),
                    .init(kind: .or(.ascii, .alphanumeric))
                )
            )
        )
    }
}
