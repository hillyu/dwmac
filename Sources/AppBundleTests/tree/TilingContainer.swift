@testable import AppBundle
import AppKit

extension TilingContainer {
    @MainActor
    static func newHMasterStack(parent: NonLeafTreeNodeObject, adaptiveWeight: CGFloat) -> TilingContainer {
        newHMasterStack(parent: parent, adaptiveWeight: adaptiveWeight, index: INDEX_BIND_LAST)
    }

    @MainActor
    static func newVMasterStack(parent: NonLeafTreeNodeObject, adaptiveWeight: CGFloat) -> TilingContainer {
        newVMasterStack(parent: parent, adaptiveWeight: adaptiveWeight, index: INDEX_BIND_LAST)
    }
}
