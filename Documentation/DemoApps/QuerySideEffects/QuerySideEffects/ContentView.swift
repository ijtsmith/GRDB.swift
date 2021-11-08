import Query
import SwiftUI
import GRDB

struct PlayerRequest: Queryable {
    static var defaultValue: Player? { nil }
    
    func publisher(in dbQueue: DatabaseQueue) -> DatabasePublishers.Value<Player?> {
        sharedPlayerObservation.publisher()
    }
}

struct ContentView: View {
    @Environment(\.dbQueue) private var dbQueue
    @Query(PlayerRequest(), in: \.dbQueue) private var player
    @State private var sheetIsPresented = false
    
    var body: some View {
        VStack {
            Group {
                if let player = player {
                    Text(player.name)
                    Spacer()
                    Button("Edit Player") {
                        sheetIsPresented = true
                    }
                    Spacer()
                    Button("Edit Player Then Delete") {
                        sheetIsPresented = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            _ = try! dbQueue.write(Player.deleteAll)
                        }
                    }
                } else {
                    Text("No player")
                    Spacer()
                    Button("Create Player") {
                        try? dbQueue.write { db in
                            try Player(id: 1, name: "Arthur").insert(db)
                        }
                    }
                    Spacer()
                    Button("Edit Missing Player") {
                        sheetIsPresented = true
                    }
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $sheetIsPresented) {
            MyOptionalSheetView(PlayerRequest(), in: \.dbQueue) { player, canDelete in
                SheetContentView(player: player, canDelete: canDelete)
            }
        }
    }
}

struct MyOptionalSheetView<Request: Queryable, Value, Content>: View
where Request.Value == Value?,
      Request.DatabaseContext == DatabaseQueue,
      Content: View
{
    @Environment(\.dbQueue) private var dbQueue
    @Environment(\.dismiss) private var dismiss
    @Query<Request> private var trackedValue: Value?
    @State private var lastKnownValue: Value?
    private var content: (_ value: Value, _ canDelete: Bool) -> Content
    private var value: Value? {
        trackedValue ?? lastKnownValue
    }
    
    init(
        _ request: Request,
        in keyPath: KeyPath<EnvironmentValues, Request.DatabaseContext>,
        @ViewBuilder content: @escaping (_ value: Value, _ canDelete: Bool) -> Content)
    {
        self._trackedValue = Query(request, in: keyPath)
        self.content = content
    }
    
    var body: some View {
        Group {
            if let value = value {
                content(value, /* canDelete */ trackedValue != nil)
            } else {
                VStack {
                    Text("Oops! No value!")
                    Spacer()
                    Button("Dismiss") { dismiss() }
                    Spacer()
                }.padding()
            }
        }
        .onAppear {
            if let value = trackedValue {
                lastKnownValue = value
            }
        }
        .onChange(of: (trackedValue != nil), perform: { valueExists in
            if !valueExists {
                dismiss()
            } else {
                lastKnownValue = trackedValue
            }
        })
    }
}

struct SheetContentView: View {
    @Environment(\.dbQueue) private var dbQueue // could be closure
    var player: Player
    var canDelete: Bool
    
    var body: some View {
        VStack {
            Text(player.name)
            Spacer()
            Button("Delete Player") {
                _ = try? dbQueue.write { db in
                    try player.delete(db)
                }
            }
            .disabled(!canDelete)
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
