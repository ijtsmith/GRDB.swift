import GRDB
import SwiftUI

@main
struct QuerySideEffectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

let demoDatabaseQueue: DatabaseQueue = {
    let dbQueue = DatabaseQueue()
    try! dbQueue.write { db in
        try db.create(table: "player") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
        }
    }
    return dbQueue
}()

let sharedPlayerObservation = ValueObservation
    .tracking(Player.fetchOne)
    .print()
    .shared(in: demoDatabaseQueue, scheduling: .immediate)

private struct DatabaseQueueKey: EnvironmentKey {
    static var defaultValue: DatabaseQueue { demoDatabaseQueue }
}

extension EnvironmentValues {
    var dbQueue: DatabaseQueue {
        get { self[DatabaseQueueKey.self] }
        set { self[DatabaseQueueKey.self] = newValue }
    }
}
