import SwiftUI

struct MyModelSafe { var title = "safe" }

struct SheetInitSafeView: View {
    @State private var model = MyModelSafe()

    var body: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                // safe: model instance created outside the closure body
                Text(model.title)
            }
    }
}
