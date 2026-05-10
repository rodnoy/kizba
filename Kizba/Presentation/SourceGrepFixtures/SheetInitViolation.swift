import SwiftUI

final class ViolationModel {}

struct SheetInitViolationView: View {
    var body: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                EmptyView()
                    .onAppear { _ = ViolationModel() }
            }
    }
}
