import SwiftUI

final class MyModel {}

struct SheetInitViolationView: View {
    var body: some View {
        Text("Hello")
            .sheet {
                MyModel()
            }
    }
}
