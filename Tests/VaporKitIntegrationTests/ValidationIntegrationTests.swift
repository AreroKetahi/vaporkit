import Testing
import VaporKit

@Suite struct ValidationIntegrationTests {
    @Test func validatableModelWorksWithVaporJSONValidation() throws {
        try CreateAccountRequest.validate(json: """
        {
            "username": "user123",
            "email": "user@example.com",
            "password": "password123"
        }
        """)

        #expect(throws: ValidationsError.self) {
            try CreateAccountRequest.validate(json: """
            {
                "username": "no", 
                "email": "not-an-email",
                "password": "short"
            }
            """)
        }
    }

    @Test func stringValidatorsWorkWithVaporJSONValidation() throws {
        try StringValidatorRequest.validate(json: """
        {
            "asciiText": "plain-ascii",
            "alphanumericCode": "abc123",
            "email": "user@example.com",
            "website": "https://example.com",
            "digits": "123456"
        }
        """)

        #expect(throws: ValidationsError.self) {
            try StringValidatorRequest.validate(json: """
            {
                "asciiText": "not-ascii❌",
                "alphanumericCode": "abc-123",
                "email": "not-an-email",
                "website": "not-a-url",
                "digits": "12ab"
            }
            """)
        }
    }

    @Test func collectionNumericAndMembershipValidatorsWorkWithVaporJSONValidation() throws {
        try CollectionAndNumericValidatorRequest.validate(json: """
        {
            "tags": ["swift", "vapor"],
            "score": 7,
            "role": "owner",
            "level": 2
        }
        """)

        #expect(throws: ValidationsError.self) {
            try CollectionAndNumericValidatorRequest.validate(json: """
            {
                "tags": ["swift"],
                "score": 42,
                "role": "guest",
                "level": 9
            }
            """)
        }
    }

    @Test func emptyNilCompositeAndCustomValidatorsWorkWithVaporJSONValidation() throws {
        try EmptyAndNilValidatorRequest.validate(json: #"{"notes":[],"deletedAt":null}"#)
        #expect(throws: ValidationsError.self) {
            try EmptyAndNilValidatorRequest.validate(json: #"{"notes":["keep"],"deletedAt":"2026-05-31"}"#)
        }

        try CompositeValidatorRequest.validate(json: #"{"displayName":"User123"}"#)
        #expect(throws: ValidationsError.self) {
            try CompositeValidatorRequest.validate(json: #"{"displayName":""}"#)
        }

        try CustomValidatorRequest.validate(json: #"{"identifier":"vk-router"}"#)
        #expect(throws: ValidationsError.self) {
            try CustomValidatorRequest.validate(json: #"{"identifier":"router"}"#)
        }
    }

    @available(macOS 14.0, *)
    @Test() func predicateValidationRuleWorksWithVaporJSONValidation() throws {
        try CreatePredicateAccountRequest.validate(json: #"{"age":21}"#)

        #expect(throws: ValidationsError.self) {
            try CreatePredicateAccountRequest.validate(json: #"{"age":17}"#)
        }
    }

    @available(macOS 14.0, *)
    @Test func externalPredicateVariableWorksWithVaporJSONValidation() throws {
        try ExternalPredicateAccountRequest.validate(json: #"{"age":21}"#)

        #expect(throws: ValidationsError.self) {
            try ExternalPredicateAccountRequest.validate(json: #"{"age":17}"#)
        }
    }

    @available(macOS 14.0, *)
    @Test func composedPredicateWorksWithOptionalVaporJSONValidation() throws {
        try ComposedPredicateProfileRequest.validate(json: #"{"name":"VaporKit"}"#)
        try ComposedPredicateProfileRequest.validate(json: #"{}"#)

        #expect(throws: ValidationsError.self) {
            try ComposedPredicateProfileRequest.validate(json: #"{"name":""}"#)
        }
    }
}
