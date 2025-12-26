import AppKit
import Common

open class DwNode: Equatable, AeroAny {
    private var _children: [DwNode] = []
    var children: [DwNode] { _children }
    fileprivate final weak var _parent: NonLeafDwNodeObject? = nil
    final var parent: NonLeafDwNodeObject? { _parent }
    private let _mruChildren: MruStack<DwNode> = MruStack()
    // Usages:
    // - resize with mouse
    // - makeFloatingWindowsSeenAsTiling in focus command
    var lastAppliedLayoutVirtualRect: Rect? = nil  // as if inner gaps were always zero
    // Usages:
    // - resize with mouse
    // - drag window with mouse
    // - move-mouse command
    var lastAppliedLayoutPhysicalRect: Rect? = nil // with real inner gaps
    final var unboundStacktrace: String? = nil
    var isBound: Bool { parent != nil } // todo drop, once https://github.com/hillyu/Dwmac/issues/1215 is fixed

    @MainActor
    init(parent: NonLeafDwNodeObject, index: Int) {
        bind(to: parent, index: index)
    }

    fileprivate init() {}

    @MainActor
    @discardableResult
    func bind(to newParent: NonLeafDwNodeObject, index: Int) -> BindingData? {
        let result = unbindIfBound()

        if newParent === NilDwNode.instance {
            return result
        }
        _ = getChildParentRelation(child: self, parent: newParent) // Side effect: verify relation

        newParent._children.insert(self, at: index != INDEX_BIND_LAST ? index : newParent._children.count)
        _parent = newParent
        unboundStacktrace = nil
        // todo consider disabling automatic mru propogation
        // 1. "floating windows" in FocusCommand break the MRU because of that :(
        // 2. Misbehaved apps that abuse real window as popups https://github.com/hillyu/Dwmac/issues/106 (the
        //    last appeared window, is not necessarily the one that has the focus)
        markAsMostRecentChild()
        return result
    }

    private func unbindIfBound() -> BindingData? {
        guard let _parent else { return nil }

        let index = _parent._children.remove(element: self) ?? dieT("Can't find child in its parent")
        check(_parent._mruChildren.remove(self))
        self._parent = nil
        unboundStacktrace = getStringStacktrace()

        return BindingData(parent: _parent, index: index)
    }

    func markAsMostRecentChild() {
        guard let _parent else { return }
        _parent._mruChildren.pushOrRaise(self)
        _parent.markAsMostRecentChild()
    }

    var mostRecentChild: DwNode? {
        var iterator = _mruChildren.makeIterator()
        return iterator.next() ?? children.last
    }

    @discardableResult
    func unbindFromParent() -> BindingData {
        unbindIfBound() ?? dieT("\(self) is already unbound. The stacktrace where it was unbound:\n\(unboundStacktrace ?? "nil")")
    }

    nonisolated public static func == (lhs: DwNode, rhs: DwNode) -> Bool {
        lhs === rhs
    }

    private var userData: [String: Any] = [:]
    func getUserData<T>(key: DwNodeUserDataKey<T>) -> T? { userData[key.key] as! T? }
    func putUserData<T>(key: DwNodeUserDataKey<T>, data: T) {
        userData[key.key] = data
    }
    @discardableResult
    func cleanUserData<T>(key: DwNodeUserDataKey<T>) -> T? { userData.removeValue(forKey: key.key) as! T? }
}

struct DwNodeUserDataKey<T> {
    let key: String
}

let INDEX_BIND_LAST = -1

struct BindingData {
    let parent: NonLeafDwNodeObject
    let index: Int
}

final class NilDwNode: DwNode, NonLeafDwNodeObject {
    override private init() {
        super.init()
    }
    @MainActor static let instance = NilDwNode()
}
