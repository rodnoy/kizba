import SwiftUI

final class BadModel {}

struct SheetInitViolationView: View {
    var body: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                EmptyView()
                    .onAppear { _ = BadModel() }
            }
    }
}
