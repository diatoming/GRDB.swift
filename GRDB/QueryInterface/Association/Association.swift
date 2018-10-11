/// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
///
public protocol AssociationBase {
    var joinCondition: JoinCondition { get }
    func mapQuery(_ transform: @escaping (AssociationQuery) -> AssociationQuery) -> Self
    func joinedQuery(_ query: AssociationQuery, with joinOperator: AssociationJoinOperator) -> AssociationQuery
    func joinedQuery(_ query: QueryInterfaceQuery, with joinOperator: AssociationJoinOperator) -> QueryInterfaceQuery
}

/// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
///
/// The base protocol for all associations that define a connection between two
/// record types.
public protocol Association: AssociationBase, DerivableRequest {
    associatedtype OriginRowDecoder
    associatedtype RowDecoder
    
//    /// TODO
//    var leftKey: String { get }
//
//    /// The association key defines how rows fetched from this association
//    /// should be consumed.
//    ///
//    /// For example:
//    ///
//    ///     struct Player: TableRecord {
//    ///         // The default key of this association is the name of the
//    ///         // database table for teams, let's say "team":
//    ///         static let team = belongsTo(Team.self)
//    ///     }
//    ///     print(Player.team.key) // Prints "team"
//    ///
//    ///     // Consume rows:
//    ///     let request = Player.including(required: Player.team)
//    ///     for row in Row.fetchAll(db, request) {
//    ///         let team: Team = row["team"] // the association key
//    ///     }
//    ///
//    /// The key can be redefined with the `forKey` method:
//    ///
//    ///     let request = Player.including(required: Player.team.forKey("custom"))
//    ///     for row in Row.fetchAll(db, request) {
//    ///         let team: Team = row["custom"]
//    ///     }
//    var key: String { get }

    /// Creates an association with the given key.
    ///
    /// This new key impacts how rows fetched from the resulting association
    /// should be consumed:
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // Consume rows:
    ///     let request = Player.including(required: Player.team.forKey("custom"))
    ///     for row in Row.fetchAll(db, request) {
    ///         let team: Team = row["custom"]
    ///     }
    func forKey(_ key: String) -> Self
    
    // TODO: remove
    var query: AssociationQuery { get }

//    /// :nodoc:
//    func query(_ joinOperator: AssociationJoinOperator) -> AssociationQuery

//    /// :nodoc:
//    var joinCondition: JoinCondition { get }
//
//    /// :nodoc:
//    func mapQuery(_ transform: @escaping (AssociationQuery) -> AssociationQuery) -> Self
//    func joinedQuery(_ query: AssociationQuery, with joinOperator: AssociationJoinOperator) -> AssociationQuery
//    func joinedQuery(_ query: QueryInterfaceQuery, with joinOperator: AssociationJoinOperator) -> QueryInterfaceQuery
}

extension Association {
    /// Creates an association which selects *selection*.
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // SELECT player.*, team.color
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     let association = Player.team.select([Column("color")])
    ///     var request = Player.including(required: association)
    ///
    /// Any previous selection is replaced:
    ///
    ///     // SELECT player.*, team.color
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     let association = Player.team
    ///         .select([Column("id")])
    ///         .select([Column("color")])
    ///     var request = Player.including(required: association)
    public func select(_ selection: [SQLSelectable]) -> Self {
        return mapQuery { $0.select(selection) }
    }
    
    /// Creates an association with the provided *predicate promise* added to
    /// the eventual set of already applied predicates.
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // SELECT player.*, team.*
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId AND 1
    ///     let association = Player.team.filter { db in true }
    ///     var request = Player.including(required: association)
    public func filter(_ predicate: @escaping (Database) throws -> SQLExpressible) -> Self {
        return mapQuery { $0.filter(predicate) }
    }
    
    /// Creates an association with the provided *orderings promise*.
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // SELECT player.*, team.*
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     // ORDER BY team.name
    ///     let association = Player.team.order { _ in [Column("name")] }
    ///     var request = Player.including(required: association)
    ///
    /// Any previous ordering is replaced:
    ///
    ///     // SELECT player.*, team.*
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     // ORDER BY team.name
    ///     let association = Player.team
    ///         .order{ _ in [Column("color")] }
    ///         .reversed()
    ///         .order{ _ in [Column("name")] }
    ///     var request = Player.including(required: association)
    public func order(_ orderings: @escaping (Database) throws -> [SQLOrderingTerm]) -> Self {
        return mapQuery { $0.order(orderings) }
    }
    
    /// Creates an association that reverses applied orderings.
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // SELECT player.*, team.*
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     // ORDER BY team.name DESC
    ///     let association = Player.team.order(Column("name")).reversed()
    ///     var request = Player.including(required: association)
    ///
    /// If no ordering was applied, the returned association is identical.
    ///
    ///     // SELECT player.*, team.*
    ///     // FROM player
    ///     // JOIN team ON team.id = player.teamId
    ///     let association = Player.team.reversed()
    ///     var request = Player.including(required: association)
    public func reversed() -> Self {
        return mapQuery { $0.reversed() }
    }
    
    /// Creates an association with the given key.
    ///
    /// This new key helps Decodable records decode rows fetched from the
    /// resulting association:
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     struct PlayerInfo: FetchableRecord, Decodable {
    ///         let player: Player
    ///         let team: Team
    ///
    ///         static func all() -> QueryInterfaceRequest<PlayerInfo> {
    ///             return Player
    ///                 .including(required: Player.team.forKey(CodingKeys.team))
    ///                 .asRequest(of: PlayerInfo.self)
    ///         }
    ///     }
    ///
    ///     let playerInfos = PlayerInfo.all().fetchAll(db)
    ///     print(playerInfos.first?.team)
    public func forKey(_ codingKey: CodingKey) -> Self {
        return forKey(codingKey.stringValue)
    }
    
    /// Creates an association that allows you to define expressions that target
    /// a specific database table.
    ///
    /// In the example below, the "team.color = 'red'" condition in the where
    /// clause could be not achieved without table aliases.
    ///
    ///     struct Player: TableRecord {
    ///         static let team = belongsTo(Team.self)
    ///     }
    ///
    ///     // SELECT player.*, team.*
    ///     // JOIN team ON ...
    ///     // WHERE team.color = 'red'
    ///     let teamAlias = TableAlias()
    ///     let request = Player
    ///         .including(required: Player.team.aliased(teamAlias))
    ///         .filter(teamAlias[Column("color")] == "red")
    ///
    /// When you give a name to a table alias, you can reliably inject sql
    /// snippets in your requests:
    ///
    ///     // SELECT player.*, custom.*
    ///     // JOIN team custom ON ...
    ///     // WHERE custom.color = 'red'
    ///     let teamAlias = TableAlias(name: "custom")
    ///     let request = Player
    ///         .including(required: Player.team.aliased(teamAlias))
    ///         .filter(sql: "custom.color = ?", arguments: ["red"])
    public func aliased(_ alias: TableAlias) -> Self {
        return mapQuery { $0.qualified(with: alias) }
    }
}

/// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
///
/// Not to be mismatched with SQL join operators (inner join, left join).
///
/// AssociationJoinOperator is designed to be hierarchically nested, unlike
/// SQL join operators.
///
/// Consider the following request for (A, B, C) tuples:
///
///     let r = A.including(optional: A.b.including(required: B.c))
///
/// It chains three associations, the first optional, the second required.
///
/// It looks like it means: "Give me all As, along with their Bs, granted those
/// Bs have their Cs. For As whose B has no C, give me a nil B".
///
/// It can not be expressed as one left join, and a regular join, as below,
/// Because this would not honor the first optional:
///
///     -- dubious
///     SELECT a.*, b.*, c.*
///     FROM a
///     LEFT JOIN b ON ...
///     JOIN c ON ...
///
/// Instead, it should:
/// - allow (A + missing (B + C))
/// - prevent (A + (B + missing C)).
///
/// This can be expressed in SQL with two left joins, and an extra condition:
///
///     -- likely correct
///     SELECT a.*, b.*, c.*
///     FROM a
///     LEFT JOIN b ON ...
///     LEFT JOIN c ON ...
///     WHERE NOT((b.id IS NOT NULL) AND (c.id IS NULL)) -- no B without C
///
/// This is currently not implemented, and requires a little more thought.
/// I don't even know if inventing a whole new way to perform joins should even
/// be on the table. But we have a hierarchical way to express joined queries,
/// and they have a meaning:
///
///     // what is my meaning?
///     A.including(optional: A.b.including(required: B.c))
///
/// :nodoc:
public enum AssociationJoinOperator {
    case required, optional
}

/// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
///
/// The condition that links two joined tables.
///
/// We only support one kind of join condition, today: foreign keys.
///
///     SELECT ...
///     FROM book
///     JOIN author ON author.id = book.authorId
///                    <--the join condition--->
///
/// When we eventually add support for new ways to join tables, JoinCondition
/// is the type we'll need to update.
///
/// The Equatable conformance is used when we merge associations. Two
/// associations can be merged if and only if their join conditions
/// are equal:
///
///     let request = Book
///         .include(required: Book.author)
///         .include(required: Book.author)
/// :nodoc:
public struct JoinCondition: Equatable {
    var foreignKeyRequest: ForeignKeyRequest
    var originIsLeft: Bool
    
    func sqlExpression(_ db: Database, leftAlias: TableAlias, rightAlias: TableAlias) throws -> SQLExpression? {
        let foreignKeyMapping = try foreignKeyRequest.fetch(db).mapping
        let columnMapping: [(left: Column, right: Column)]
        if originIsLeft {
            columnMapping = foreignKeyMapping.map { (left: Column($0.origin), right: Column($0.destination)) }
        } else {
            columnMapping = foreignKeyMapping.map { (left: Column($0.destination), right: Column($0.origin)) }
        }
        
        return columnMapping
            .map { $0.right.qualifiedExpression(with: rightAlias) == $0.left.qualifiedExpression(with: leftAlias) }
            .joined(operator: .and)
    }
}

extension Association {
    /// Creates an association that includes another one. The columns of the
    /// associated record are selected. The returned association does not
    /// require that the associated database table contains a matching row.
    public func including<A: Association>(optional association: A) -> Self where A.OriginRowDecoder == RowDecoder {
        return mapQuery { association.joinedQuery($0, with: .optional) }
    }
    
    /// Creates an association that includes another one. The columns of the
    /// associated record are selected. The returned association requires
    /// that the associated database table contains a matching row.
    public func including<A: Association>(required association: A) -> Self where A.OriginRowDecoder == RowDecoder {
        return mapQuery { association.joinedQuery($0, with: .required) }
    }
    
    /// Creates an association that joins another one. The columns of the
    /// associated record are not selected. The returned association does not
    /// require that the associated database table contains a matching row.
    public func joining<A: Association>(optional association: A) -> Self where A.OriginRowDecoder == RowDecoder {
        return mapQuery { association.select([]).joinedQuery($0, with: .optional) }
    }
    
    /// Creates an association that joins another one. The columns of the
    /// associated record are not selected. The returned association requires
    /// that the associated database table contains a matching row.
    public func joining<A: Association>(required association: A) -> Self where A.OriginRowDecoder == RowDecoder {
        return mapQuery { association.select([]).joinedQuery($0, with: .required) }
    }
}

extension Association where OriginRowDecoder: MutablePersistableRecord {
    /// Support for MutablePersistableRecord.request(for:).
    ///
    /// For example:
    ///
    ///     struct Team: {
    ///         static let players = hasMany(Player.self)
    ///         var players: QueryInterfaceRequest<Player> {
    ///             return request(for: Team.players)
    ///         }
    ///     }
    ///
    ///     let team: Team = ...
    ///     let players = try team.players.fetchAll(db) // [Player]
    func request(from record: OriginRowDecoder) -> QueryInterfaceRequest<RowDecoder> {
        // Goal: turn `JOIN association ON association.recordId = record.id`
        // into a regular request `SELECT * FROM association WHERE association.recordId = 123`
        
        // We need table aliases to build the joining condition
        let associationAlias = TableAlias()
        let recordAlias = TableAlias()
        
        // Turn the association request into a query interface request:
        // JOIN association -> SELECT FROM association
        return QueryInterfaceRequest(query) // TODO: reverse everything
            
            // Turn the JOIN condition into a regular WHERE condition
            .filter { db in
                // Build a join condition: `association.recordId = record.id`
                // We still need to replace `record.id` with the actual record id.
                guard let joinExpression = try self.joinCondition.sqlExpression(db, leftAlias: recordAlias, rightAlias: associationAlias) else {
                    fatalError("Can't request from record without join condition")
                }
                
                // Serialize record: ["id": 123, ...]
                // We do it as late as possible, when request is about to be
                // executed, in order to support long-lived reference types.
                let container = PersistenceContainer(record)
                
                // Replace `record.id` with 123
                return joinExpression.resolvedExpression(inContext: [recordAlias: container])
            }
            
            // We just added a condition qualified with associationAlias. Don't
            // risk introducing conflicting aliases that would prevent the user
            // from setting a custom alias name: force the same alias for the
            // whole request.
            .aliased(associationAlias)
    }
}

/// TODO
public protocol ToOneAssociation: Association { }

/// TODO
public protocol ToManyAssociation: Association { }
