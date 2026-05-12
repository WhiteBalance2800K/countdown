import SwiftUI
import UniformTypeIdentifiers

struct ItemReorderDropDelegate: DropDelegate {
    let targetItem: CountdownItem
    let store: ItemsStore
    @Binding var draggingItemID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingItemID else { return }
        guard draggingItemID != targetItem.id else { return }

        Task { @MainActor in
            withAnimation(.interactiveSpring(response: 0.30, dampingFraction: 0.86, blendDuration: 0.10)) {
                store.moveItem(id: draggingItemID, before: targetItem.id, persistsImmediately: false)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        Task { @MainActor in
            store.saveCurrentOrder()
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                draggingItemID = nil
            }
        }
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
