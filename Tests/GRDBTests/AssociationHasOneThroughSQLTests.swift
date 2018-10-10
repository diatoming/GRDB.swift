import XCTest
#if GRDBCIPHER
    import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

/// Test SQL generation

class AssociationHasOneThroughSQLTests: GRDBTestCase {
    
    func testBelongsToBelongsTo() throws {
        struct A: TableRecord {
            static let b = belongsTo(B.self)
            static let c = hasOne(B.c, through: b)
        }
        struct B: TableRecord {
            static let c = belongsTo(C.self)
        }
        struct C: TableRecord {
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "c") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "b") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cId").references("c")
            }
            try db.create(table: "a") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("bId").references("b")
            }
            
            do {
                try assertEqualSQL(db, A.including(optional: A.c), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(required: A.c), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(optional: A.c), """
                    SELECT "a".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(required: A.c), """
                    SELECT "a".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
            }
            do {
                try assertEqualSQL(db, A.including(optional: A.c).including(optional: A.b), """
                    SELECT "a".*, "b".*, "c".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(optional: A.c).including(required: A.b), """
                    SELECT "a".*, "b".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(optional: A.c).joining(optional: A.b), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(optional: A.c).joining(required: A.b), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
            }
            do {
                try assertEqualSQL(db, A.including(required: A.c).including(optional: A.b), """
                    SELECT "a".*, "b".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(required: A.c).including(required: A.b), """
                    SELECT "a".*, "b".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(required: A.c).joining(optional: A.b), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.including(required: A.c).joining(required: A.b), """
                    SELECT "a".*, "c".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
            }
            do {
                try assertEqualSQL(db, A.joining(optional: A.c).including(optional: A.b), """
                    SELECT "a".*, "b".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(optional: A.c).including(required: A.b), """
                    SELECT "a".*, "b".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(optional: A.c).joining(optional: A.b), """
                    SELECT "a".* \
                    FROM "a" \
                    LEFT JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(optional: A.c).joining(required: A.b), """
                    SELECT "a".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    LEFT JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
            }
            do {
                try assertEqualSQL(db, A.joining(required: A.c).including(optional: A.b), """
                    SELECT "a".*, "b".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(required: A.c).including(required: A.b), """
                    SELECT "a".*, "b".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(required: A.c).joining(optional: A.b), """
                    SELECT "a".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
                try assertEqualSQL(db, A.joining(required: A.c).joining(required: A.b), """
                    SELECT "a".* \
                    FROM "a" \
                    JOIN "b" ON ("b"."id" = "a"."bId") \
                    JOIN "c" ON ("c"."id" = "b"."cId")
                    """)
            }
        }
    }
    
    func testBelongsToHasOne() throws {
        
    }
    
    func testHasOneBelongsTo() throws {
        
    }
    
    func testHasOneHasOne() throws {
        
    }
    
    func testBelongsToBelongsToBelongsTo() throws {
        
    }
    
    func testBelongsToBelongsToHasOne() throws {
        
    }
    
    func testBelongsToHasOneBelongsTo() throws {
        
    }
    
    func testBelongsToHasOneHasOne() throws {
        
    }
    
    func testHasOneBelongsToBelongsTo() throws {
        
    }
    
    func testHasOneBelongsToHasOne() throws {
        
    }
    
    func testHasOneHasOneBelongsTo() throws {
        
    }
    
    func testHasOneHasOneHasOne() throws {
        
    }
}
