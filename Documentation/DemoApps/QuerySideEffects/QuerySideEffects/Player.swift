import GRDB

struct Player: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: Int64
    var name: String
}
