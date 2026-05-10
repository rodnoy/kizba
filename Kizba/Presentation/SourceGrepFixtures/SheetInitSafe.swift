import SwiftUI

final class MyModelSafe: ObservableObject {}

struct SheetInitSafeView: View {
    @StateObject private var model = MyModelSafe()

    var body: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                // safe: pass model into the sheet rather than initializing here
                Text("Sheet")
            }
    }
}
