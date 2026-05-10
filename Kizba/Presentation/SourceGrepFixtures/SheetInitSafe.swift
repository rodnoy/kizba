import SwiftUI

final class MyModelSafe {}

struct SheetInitSafeView: View {
    @StateObject private var model = MyModelSafe()

    var body: some View {
        Text("Hello")
            .sheet {
                // safe: pass model into the sheet rather than initializing here
                Text("Sheet")
            }
    }
}
