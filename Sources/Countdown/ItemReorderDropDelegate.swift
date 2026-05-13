import SwiftUI
import UniformTypeIdentifiers

struct ItemReorderDropDelegate: DropDelegate {
    enum Placement {
        case before
        case after
        case end
    }

    let targetItem: CountdownItem
    let store: ItemsStore
    @Binding var draggingItemID: UUID?
    let placement: Placement

    func dropEntered(info: DropInfo) {
        guard let draggingItemID else { return }

        Task { @MainActor in
            withAnimation(.interactiveSpring(response: 0.30, dampingFraction: 0.86, blendDuration: 0.10)) {
                move(draggingItemID)
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

    private func move(_ draggingItemID: UUID) {
        switch placement {
        case .before:
            store.moveItem(id: draggingItemID, before: targetItem.id, persistsImmediately: false)
        case .after:
            store.moveItem(id: draggingItemID, after: targetItem.id, persistsImmediately: false)
        case .end:
            store.moveItemToEnd(id: draggingItemID, persistsImmediately: false)
        }
    }
}
