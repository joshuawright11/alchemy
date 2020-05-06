import Foundation

public class Query {

    let database: Database

    var columns: [String]? = nil
    private(set) var from: String?
    private(set) var joins: [JoinClause]? = nil
    private(set) var wheres: [WhereClause] = []
    private(set) var groups: [String] = []
    private(set) var havings: [Any] = []
    private(set) var orders: [OrderClause] = []
    private(set) var limit: Int? = nil
    private(set) var offset: Int = 0

    public var distinct = false

    init(database: Database) {
        self.database = database
    }

    public func toSQL() -> SQL {
        return database.grammar.compileSelect(query: self)
    }

    func isQueryable(column: Any) -> Bool {
        return false
    }

    public func select(_ columns: [Any] = ["*"]) -> Query {

        self.columns = []
        for column in columns {

            if let column = column as? String {
                self.columns?.append(column)
            }
            else {
                // Need to check if queryable & closures
            }
        }
        return self
    }

    //    func selectRaw(expression, array bindings)
    //
    //    func selectRaw(var expression, bindings) {
    //
    //    }

    public func from(table: ModelTable) -> Query {
        return from(table: table.name)
    }

    public func from(table: String, as alias: String? = nil) -> Query {

        //TODO: Something about subquery

        guard let alias = alias else {
            self.from = table
            return self
        }
        self.from = "\(table) as \(alias)"
        return self
    }

    //    join(table, first, operator, second, type, where)
    //    leftJoin(table, first, operator, second)
    //    rightJoin(table, first, operator, second)
    //    crossJoin(table, first, operator, second)

    public func `where`(_ clause: WhereValue) -> Query {
        self.wheres.append(clause)
        return self
    }

    public func orWhere(_ clause: WhereValue) -> Query {
        var clause = clause
        clause.boolean = .or
        self.wheres.append(clause)
        return self
    }

    public func `where`(
        key: String,
        in values: [Parameter],
        type: WhereIn.InType = .in,
        boolean: WhereBoolean = .and
    ) -> Query {
        self.wheres.append(WhereIn(key: key, values: values, type: type, boolean: boolean))
        return self
    }

    public func orWhere(key: String, in values: [Parameter], type: WhereIn.InType = .in) -> Query {
        return self.where(
            key: key,
            in: values,
            type: type,
            boolean: .or
        )
    }

    public func `where`(_ closure: @escaping WhereNestedClosure, boolean: WhereBoolean = .and) -> Query {
        self.wheres.append(
            WhereNested(
                database: database,
                closure: closure,
                boolean: boolean
            )
        )
        return self
    }

    public func orWhere(_ closure: @escaping WhereNestedClosure) -> Query {
        return self.where(closure, boolean: .or)
    }

    public func whereNot(key: String, in values: [Parameter], boolean: WhereBoolean = .and) -> Query {
        return self.where(key: key, in: values, type: .notIn, boolean: boolean)
    }

    public func orWhereNot(key: String, in values: [Parameter]) -> Query {
        return self.where(key: key, in: values, type: .notIn, boolean: .or)
    }

    public func whereRaw(sql: String, bindings: [Parameter], boolean: WhereBoolean = .and) -> Query {
        self.wheres.append(WhereRaw(query: sql, values: bindings, boolean: boolean))
        return self
    }

    public func orWhereRaw(sql: String, bindings: [Parameter]) -> Query {
        return self.whereRaw(sql: sql, bindings: bindings, boolean: .or)
    }

    @discardableResult
    public func whereColumn(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> Query {
        self.wheres.append(WhereColumn(first: first, op: op, second: Expression(second), boolean: boolean))
        return self
    }

    //    whereNull(column, boolean = "and", not = false)
    //    orWhereNull(column) = whereNull(column, "or")
    //    whereNotNull(column, boolean = "and") = whereNull(column, boolean, true)
    //    having(column, operator, value, boolean = "and")
    //    orHaving(column, operator, value) = having(column, operator, value, "or")

    public func groupBy(_ group: String) -> Query {
        self.groups.append(group)
        return self
    }

    public func orderBy(_ order: OrderClause) -> Query {
        self.orders.append(order)
        return self
    }

    public func orderBy(column: String, direction: OrderClause.Sort = .asc) -> Query {
        //TODO: Add support for sort subquery
        return self.orderBy(OrderClause(column: column, direction: direction))
    }



    public func offset(_ value: Int) -> Query {
        self.offset = max(0, value)
        return self
    }

    public func limit(_ value: Int) -> Query {
        if (value >= 0) {
            self.limit = value
        }
        return self
    }

    // Paging starts at index 1, not zero
    public func forPage(page: Int, perPage: Int = 25) -> Query {
        return offset((page - 1) * perPage).limit(perPage)
    }

//    public func get($columns = ["*"])
//    {
//        return collect($this->onceWithColumns(Arr::wrap($columns), function () {
//            return $this->processor->processSelect($this, $this->runSelect());
//        }));
//    }
    //
//    func first(_ columns: [String]) {
//
//    }
    //
    //    private func onceWithColumns($columns, $callback)
    //    {
    //        let original = self.columns
    //        if original.isEmpty {
    //            self.columns = columns
    //        }
    //
    //        let result =
    //
    //        if (is_null($original)) {
    //            $this->columns = $columns;
    //        }
    //
    //        $result = $callback();
    //
    //        $this->columns = $original;
    //
    //        return $result;
    //    }


    // Query for a single record by ID
    //    func find(id: Identifier, columns = ["*"]) -> Builder {
    //        return `where`(column: "id", operator: <#T##<<error type>>#>, value: <#T##String#>)
    //    }

    //    get(columns = ["*"])
    //    paginate(perPage, columns, page)
    //    count()
    //    exists()
    //
    public func insert(value: [String: Parameter]) throws -> SQL {
        return try insert(values: [value])
    }

    public func insert(values: [[String: Parameter]]) throws -> SQL {
        if values.isEmpty { return SQL() }

        return try database.grammar.compileInsert(self, values: values)
    }

    public func update(values: [String: Parameter]) throws -> SQL {
        return try database.grammar.compileUpdate(self, values: values)
    }

    //    update(values)
    //    updateOrInsert()
    //    delete(id = null)
}


extension String {
    public static func ==(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .equals, value: rhs)
    }

    public static func !=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .notEqualTo, value: rhs)
    }

    public static func <(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThan, value: rhs)
    }

    public static func >(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThan, value: rhs)
    }

    public static func <=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThanOrEqualTo, value: rhs)
    }

    public static func >=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThanOrEqualTo, value: rhs)
    }

    public static func ~=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .like, value: rhs)
    }
}
