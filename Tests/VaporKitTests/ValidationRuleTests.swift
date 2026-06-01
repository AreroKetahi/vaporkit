import Testing
import Foundation
@testable import VaporKit

@Suite struct ValidationRuleTests {
    @Test func namedRulesPreserveStableDescriptions() {
        #expect(ValidationRule.email.description == ".email")
        #expect(ValidationRule.ascii.description == ".ascii")
        #expect(ValidationRule.url.description == ".url")
        #expect(ValidationRule.nil.description == ".nil")
    }

    @Test func argumentRulesPreserveStableDescriptions() {
        #expect(ValidationRule.count(3...).description == ".count(3...)")
        #expect(ValidationRule.range(18...).description == ".range(18...)")
        #expect(ValidationRule.range(18...65).description == ".range(18...65)")
        #expect(ValidationRule.range(18..<65).description == ".range(18..<65)")
        #expect(ValidationRule.count(...32).description == ".count(...32)")
        #expect(ValidationRule.count(..<32).description == ".count(..<32)")
        #expect(ValidationRule.in("owner", "maintainer").description == #".in("owner", "maintainer")"#)
        #expect(ValidationRule.in(1, 2, 3).description == ".in(1, 2, 3)")
        #expect(
            ValidationRule.characterSet(.decimalDigits).description
            ==
            ".characterSet(<CFCharacterSet Predefined DecimalDigit Set>)"
        )
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    @Test func predicateRulePreservesStableDescription() {
        let rule = ValidationRule.predicate(#Predicate<Int> { $0 >= 18 })

        #expect(rule.description == ".predicate(<predicate>)")
        #expect(rule == .init(kind: .predicate))
    }

    @Test func compositeRulesBuildAnActualRuleTree() {
        let rule = !ValidationRule.empty && (.ascii || .alphanumeric)

        #expect(rule.description == "!.empty && (.ascii || .alphanumeric)")
        #expect(
            rule
            ==
            .init(
                kind: .and(
                    .init(kind: .not(.empty)),
                    .init(kind: .or(.ascii, .alphanumeric))
                )
            )
        )
    }
}
