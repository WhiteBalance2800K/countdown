import SwiftUI
import UniformTypeIdentifiers

struct ItemReorderDropDelegate: DropDelegate {
    let targetItem: CountdownItem
    let store: ItemsStore
    @Binding var draggingItemID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingItemID else { return }
        guard draggingItemID != targetItem.id else { return }

        // Keep the underlying array order in sync as the user hovers.
        Task { @MainActor in
            store.moveItem(id: draggingItemID, before: targetItem.id)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
