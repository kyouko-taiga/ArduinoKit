/// A reducer.
protocol Reducer {

  /// The type of messages processed by this reducer.
  associatedtype Message

  /// The type of this reducer's state (a.k.a. context).
  associatedtype State: Hashable

  /// Processes `message` in the context of `state` to produce a potentially updated state.
  func reduce(message: Message, in state: State) -> State

  /// This reducer's initial state.
  static var initialState: State { get }

}

/// An opaque reducer.
struct SomeReducer<Message> {

  let initialState: AnyHashable
  private let _reduce: (Any, Any) -> AnyHashable

  init<R>(_ reducer: R) where R: Reducer {
    self.initialState = R.initialState
    self._reduce = { message, state in
      return reducer.reduce(message: message as! R.Message, in: state as! R.State)
    }
  }

  func reduce(message: Message, in state: Any) -> AnyHashable? {
    return _reduce(message, state)
  }

}
