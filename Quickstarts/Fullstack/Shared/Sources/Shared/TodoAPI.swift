import Papyrus

public final class TodoAPI: EndpointGroup {
    @GET("/todo")
    public var getAll: Endpoint<Empty, [TodoDTO]>
    
    @POST("/todo")
    public var create: Endpoint<CreateTodoRequest, TodoDTO>
    
    @DELETE("/todo/:todoID")
    public var delete: Endpoint<DeleteTodoRequest, Empty>
}

extension TodoAPI {
    
    // MARK: - TodoAPI Requests
    
    /// Request data for creating a new todo.
    public struct CreateTodoRequest: EndpointRequest {
        public struct DTO: Codable {
            public let name: String
            public let tagIDs: [Int]
            
            public init(name: String, tagIDs: [Int]) {
                self.name = name
                self.tagIDs = tagIDs
            }
        }
        
        @Body
        public var dto: DTO
        
        public init(dto: DTO) {
            self.dto = dto
        }
    }
    
    /// Request data for deleting a todo.
    public struct DeleteTodoRequest: EndpointRequest {
        @Path
        public var todoID: String
        
        public init(todoID: String) {
            self.todoID = todoID
        }
    }
    
    // MARK: - TodoAPI DTOs
    
    /// A todo item, with associated tags.
    public struct TodoDTO: Codable {
        let id: Int
        let name: String
        let isComplete: Bool
        let tags: [UserAPI.TagDTO]
        
        public init(id: Int, name: String, isComplete: Bool, tags: [UserAPI.TagDTO]) {
            self.id = id
            self.name = name
            self.isComplete = isComplete
            self.tags = tags
        }
    }
}
