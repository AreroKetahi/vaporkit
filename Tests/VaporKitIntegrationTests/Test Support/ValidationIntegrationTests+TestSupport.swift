import Foundation
import VaporKit

@ValidatableModel
struct CreateAccountRequest: Content {
    @Constraint(.alphanumeric && .count(3...16))
    var username: String

    @Constraint(.email)
    var email: String

    @Constraint(.count(8...), message: "Password is too short.")
    var password: String
}

@ValidatableModel
struct StringValidatorRequest: Content {
    @Constraint(.ascii)
    var asciiText: String

    @Constraint(.alphanumeric)
    var alphanumericCode: String

    @Constraint(.email)
    var email: String

    @Constraint(.url)
    var website: String

    @Constraint(.characterSet(.decimalDigits))
    var digits: String
}

@ValidatableModel
struct CollectionAndNumericValidatorRequest: Content {
    @Constraint(.count(2...3))
    var tags: [String]

    @Constraint(.range(1...10))
    var score: Int

    @Constraint(.in("owner", "maintainer"))
    var role: String

    @Constraint(.in(1, 2, 3))
    var level: Int
}

@ValidatableModel
struct EmptyAndNilValidatorRequest: Content {
    @Constraint(.empty)
    var notes: [String]

    @Constraint(.nil)
    var deletedAt: String?
}

@ValidatableModel
struct CompositeValidatorRequest: Content {
    @Constraint(!.empty && (.ascii || .alphanumeric))
    var displayName: String
}

@ValidatableModel
struct CustomValidatorRequest: Content {
    @Constraint(validating: String.self, message: "Identifier must use the vk prefix", with: { value in
        value.hasPrefix("vk-")
    })
    var identifier: String
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@ValidatableModel
struct CreatePredicateAccountRequest: Content {
    @Constraint(.predicate(#Predicate<Int> { $0 >= 18 }), message: "Must be an adult.")
    var age: Int
}

@available(macOS 14.0, *)
let adultPredicate = #Predicate<Int> { $0 >= 18 }

@available(macOS 14.0, *)
@ValidatableModel
struct ExternalPredicateAccountRequest: Content {
    @Constraint(.predicate(adultPredicate), message: "Must be an adult.")
    var age: Int
}

@available(macOS 14.0, *)
@ValidatableModel
struct ComposedPredicateProfileRequest: Content {
    @Constraint(.predicate(#Predicate<String> { !$0.isEmpty }) && .count(...32))
    var name: String?
}
