import Foundation
import Testing
import Vapor
@testable import VaporKit

@OpenAPISchema
private struct OpenAPITestDTO {
    var id: UUID
    var nickname: String?
    var scores: [Int]
}

@OpenAPISchema
private struct DocumentedOpenAPITestDTO {
    @OpenAPIProperty(
        .format(.email),
        .description("Account email"),
        .maxLength(254),
        .readOnly
    )
    var email: String

    @OpenAPIProperty(
        .description("Account password"),
        .minLength(8),
        .pattern(regex: #"^[^\s]+$"#),
        .writeOnly
    )
    var password: String?
}

@Suite struct OpenAPITests {
    @Test func schemaMacroGeneratesPropertiesAndRequiredNames() throws {
        let schema = OpenAPITestDTO.openAPISchema
        #expect(schema.type == .object)
        #expect(schema.properties?["id"]?.format == .uuid)
        #expect(schema.properties?["nickname"]?.types == [.string, .null])
        #expect(schema.properties?["scores"]?.items?.schema.type == .integer)
        #expect(schema.required == ["id", "scores"])
    }

    @Test func propertyAttributesRefineInferredSchemas() throws {
        let schema = DocumentedOpenAPITestDTO.openAPISchema
        let email = try #require(schema.properties?["email"])
        #expect(email.type == .string)
        #expect(email.format == .email)
        #expect(email.description == "Account email")
        #expect(email.maxLength == 254)
        #expect(email.readOnly == true)

        let password = try #require(schema.properties?["password"])
        #expect(password.types == [.string, .null])
        #expect(password.description == "Account password")
        #expect(password.minLength == 8)
        #expect(password.pattern == #"^[^\s]+$"#)
        #expect(password.writeOnly == true)
        #expect(schema.required == ["email"])

        let data = try JSONEncoder().encode(schema)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let properties = try #require(object["properties"] as? [String: Any])
        let encodedEmail = try #require(properties["email"] as? [String: Any])
        #expect(encodedEmail["format"] as? String == "email")
        #expect(encodedEmail["readOnly"] as? Bool == true)
        #expect(encodedEmail["writeOnly"] == nil)
    }

    @Test func parameterMetadataRefinesItsInferredSchema() throws {
        func passthrough(
            @OpenAPIParameter(
                description: "Search term",
                schema: .minLength(2), .maxLength(100)
            )
            @Query value: String
        ) -> String {
            value
        }
        #expect(passthrough(value: "ok") == "ok")

        let router = _OpenAPIRouterDescriptor(
            identifier: "Search",
            path: "search",
            handlers: [
                .init(
                    identifier: "Search.index",
                    method: "GET",
                    path: "",
                    parameters: [
                        .init(
                            name: "query",
                            location: "query",
                            schema: String.self,
                            required: true,
                            description: "Search term",
                            deprecated: true,
                            allowEmptyValue: true,
                            schemaModifiers: [.minLength(2), .maxLength(100)]
                        )
                    ]
                )
            ],
            registeredRouters: []
        )
        let document = try OpenAPIDocumentBuilder().build(
            title: "Search",
            version: "1",
            descriptors: [router]
        )
        let parameter = try #require(document.paths["/search"]?["get"]?.parameters?.first)
        #expect(parameter.description == "Search term")
        #expect(parameter.deprecated == true)
        #expect(parameter.allowEmptyValue == true)
        #expect(parameter.schema.type == .string)
        #expect(parameter.schema.minLength == 2)
        #expect(parameter.schema.maxLength == 100)
    }

    @Test func optionalSchemaEncodesAnOpenAPI31TypeUnion() throws {
        let data = try JSONEncoder().encode(String?.openAPISchema)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? [String] == ["string", "null"])
        #expect(object["nullable"] == nil)
    }

    @Test func stringKeyedDictionaryUsesAdditionalPropertiesSchema() throws {
        let schema = [String: OpenAPITestDTO].openAPISchema
        #expect(schema.type == .object)
        #expect(schema.additionalProperties?.schema.type == .object)
        #expect(schema.additionalProperties?.schema.properties?["id"]?.format == .uuid)

        let data = try JSONEncoder().encode(schema)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let additionalProperties = try #require(object["additionalProperties"] as? [String: Any])
        #expect(additionalProperties["type"] as? String == "object")
    }

    @Test func registeredRouterPathsAreResolvedByIdentifier() throws {
        let root = _OpenAPIRouterDescriptor(
            identifier: "RootRouter",
            path: "api",
            handlers: [],
            registeredRouters: ["UserRouter"]
        )
        let users = _OpenAPIRouterDescriptor(
            identifier: "UserRouter",
            path: "users",
            handlers: [
                .init(
                    identifier: "UserRouter.user",
                    method: "GET",
                    path: ":id",
                    parameters: [
                        .init(name: "id", location: "path", schema: UUID.self, required: true),
                        .init(name: "include", location: "query", schema: Bool?.self, required: false),
                    ],
                    responses: [
                        .init(status: .ok, body: String.self)
                    ],
                    operationID: "getUser"
                )
            ],
            registeredRouters: []
        )

        let document = try OpenAPIDocumentBuilder().build(
            title: "Test API",
            version: "1.0.0",
            descriptors: [users, root]
        )

        let operation = try #require(document.paths["/api/users/{id}"]?["get"])
        #expect(operation.operationId == "getUser")
        #expect(operation.parameters?.map(\.name) == ["id", "include"])
        #expect(operation.responses["200"]?.content?["application/json"]?.schema.type == .string)
    }

    @Test func neverResponseHasNoBodyContent() throws {
        let router = _OpenAPIRouterDescriptor(
            identifier: "SessionRouter",
            path: "sessions",
            handlers: [
                .init(
                    identifier: "SessionRouter.logout",
                    method: "POST",
                    path: "logout",
                    responses: [.init(status: .ok, body: Never.self)]
                )
            ],
            registeredRouters: []
        )

        let document = try OpenAPIDocumentBuilder().build(
            title: "Test API",
            version: "1.0.0",
            descriptors: [router]
        )

        let response = try #require(document.paths["/sessions/logout"]?["post"]?.responses["200"])
        #expect(response.content == nil)
    }

    @Test func requestBodyAndTypedParameterSchemasAreEmitted() throws {
        let router = _OpenAPIRouterDescriptor(
            identifier: "Users",
            path: "users",
            handlers: [
                .init(
                    identifier: "Users.create",
                    method: "POST",
                    path: "",
                    parameters: [
                        .init(
                            name: "filter",
                            location: "query",
                            schema: OpenAPITestDTO.self,
                            required: true
                        )
                    ],
                    requestBody: .init(body: OpenAPITestDTO.self),
                    responses: [.init(status: .created, body: OpenAPITestDTO.self)]
                )
            ],
            registeredRouters: []
        )

        let document = try OpenAPIDocumentBuilder().build(
            title: "Test",
            version: "1",
            descriptors: [router]
        )
        let operation = try #require(document.paths["/users"]?["post"])
        #expect(
            operation.parameters?.first?.schema.reference
                == "#/components/schemas/OpenAPITestDTO"
        )
        #expect(operation.requestBody?.required == true)
        #expect(
            operation.requestBody?.content["application/json"]?.schema.reference
                == "#/components/schemas/OpenAPITestDTO"
        )
        #expect(operation.responses["201"]?.content?["application/json"]?.schema.reference
            == "#/components/schemas/OpenAPITestDTO")
        #expect(document.components?.schemas["OpenAPITestDTO"] == OpenAPITestDTO.openAPISchema)
    }

    @Test func oneRouterCanBeExpandedUnderMultipleParents() throws {
        let shared = _OpenAPIRouterDescriptor(
            identifier: "SharedRouter",
            path: "items",
            handlers: [.init(identifier: "SharedRouter.list", method: "GET", path: "", parameters: [], responses: [])],
            registeredRouters: []
        )
        let v1 = _OpenAPIRouterDescriptor(
            identifier: "V1", path: "v1", handlers: [], registeredRouters: ["SharedRouter"]
        )
        let v2 = _OpenAPIRouterDescriptor(
            identifier: "V2", path: "v2", handlers: [], registeredRouters: ["SharedRouter"]
        )

        let document = try OpenAPIDocumentBuilder().build(
            title: "Test", version: "1", descriptors: [shared, v2, v1]
        )
        #expect(document.paths["/v1/items"]?["get"] != nil)
        #expect(document.paths["/v2/items"]?["get"] != nil)
    }

    @Test func missingAndCyclicRouterRelationshipsFail() throws {
        let missing = _OpenAPIRouterDescriptor(
            identifier: "Root", path: "", handlers: [], registeredRouters: ["Missing"]
        )
        #expect(throws: OpenAPIDocumentBuilderError.self) {
            try OpenAPIDocumentBuilder().build(title: "Test", version: "1", descriptors: [missing])
        }

        let a = _OpenAPIRouterDescriptor(
            identifier: "A", path: "a", handlers: [], registeredRouters: ["B"]
        )
        let b = _OpenAPIRouterDescriptor(
            identifier: "B", path: "b", handlers: [], registeredRouters: ["A"]
        )
        #expect(throws: OpenAPIDocumentBuilderError.self) {
            try OpenAPIDocumentBuilder().build(title: "Test", version: "1", descriptors: [a, b])
        }
    }

    @Test func duplicateResponseStatusFailsWithoutTrapping() throws {
        let router = _OpenAPIRouterDescriptor(
            identifier: "Users",
            path: "users",
            handlers: [
                .init(
                    identifier: "Users.show",
                    method: "GET",
                    path: ":id",
                    responses: [
                        .init(status: .ok, body: String.self),
                        .init(status: .ok, body: OpenAPITestDTO.self),
                    ]
                )
            ],
            registeredRouters: []
        )

        #expect(throws: OpenAPIDocumentBuilderError.self) {
            try OpenAPIDocumentBuilder().build(
                title: "Test",
                version: "1",
                descriptors: [router]
            )
        }
    }

    @Test func exporterProducesOpenAPI31JSON() throws {
        let descriptor = _OpenAPIRouterDescriptor(
            identifier: "HealthRouter",
            path: "api",
            handlers: [.init(identifier: "HealthRouter.health", method: "GET", path: "health")],
            registeredRouters: []
        )
        let data = try OpenAPIExporter.data(
            title: "Health",
            version: "1.0.0",
            descriptors: [descriptor]
        )
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["openapi"] as? String == "3.1.0")
        let paths = try #require(object["paths"] as? [String: Any])
        #expect(paths["/api/health"] != nil)
    }
}
