import Foundation
import Testing
import VaporKitOpenAPI

@OpenAPISchema
private struct LightweightSchemaFixture {
    var id: UUID
    var createdAt: Date
    var labels: [String]
}

@Suite struct VaporKitOpenAPITests {
    @Test func schemaModuleWorksWithoutImportingVapor() {
        let schema = LightweightSchemaFixture.openAPISchema
        #expect(schema.type == .object)
        #expect(schema.properties?["id"]?.format == .uuid)
        #expect(schema.properties?["createdAt"]?.type == .string)
        #expect(schema.properties?["createdAt"]?.format == .dateTime)
        #expect(schema.properties?["labels"]?.type == .array)
    }
}
