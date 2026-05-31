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
