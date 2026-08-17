import Vapor

extension Parameters {
    /// Decodes a captured path parameter as a URL-encoded scalar value.
    public func decode<Value: Decodable>(
        _ name: String,
        as type: Value.Type = Value.self
    ) throws -> Value {
        let value = try require(name)
        do {
            return try URLEncodedFormDecoder().decode(type, from: value)
        } catch {
            logger.debug("The parameter \(value) could not be decoded as \(Value.self)")
            throw Abort(
                .unprocessableEntity,
                reason: "The parameter value could not be decoded as the required type"
            )
        }
    }
}
