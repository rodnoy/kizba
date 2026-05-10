import SwiftUI

// kizba:allow-sheet-init
final class MyModelAllowed {}

struct SheetInitAllowedView: View {
    var body: some View {
        Text("Hello")
            .sheet {
                MyModelAllowed()
            }
    }
}
