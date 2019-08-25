/// A store listener.
///
/// A listener is merely a functor that is triggered when the state of the store to which it is
/// attached changes.
protocol Listener {

  associatedtype Message
  associatedtype StateKey: Hashable

  /// The function that is called when the listener is triggered.
  func callback(store: inout Store<StateKey, Message>)

}

/// A type erased listener.
struct AnyListener<StateKey, Message>: Listener where StateKey: Hashable {

  private let _callback: (inout Store<StateKey, Message>) -> Void

  init<L>(_ listener: L) where L: Listener, L.StateKey == StateKey, L.Message == Message {
    self._callback = listener.callback
  }

  func callback(store: inout Store<StateKey, Message>) {
    _callback(&store)
  }

}
