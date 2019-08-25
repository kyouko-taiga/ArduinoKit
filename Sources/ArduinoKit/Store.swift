/// A store.
///
/// A store is a standard "pub/sub" system, but that uses a state as an intermediate data structure
/// to uncouple message publishers and subsribers. That state can be updated by so-called reducers,
/// which are merely functions that process a message in the context of the current state, in order
/// to compute its successor. Note that a state should always be an immutable data structure, for
/// which all mutations are expressed in its successor.
///
/// Messages are emitted with the `dispatch(message:)` method. Once all reducers have been exucted
/// (and not before!), store listeners (a.k.a. subscribers) are triggered with the update.
///
/// Note that reducers __must not__ dispatch messages, as this would trigger infinite recursion.
/// Ideally, this constraint should be checked statically.
struct Store<Key, Message> where Key: Hashable {

  /// The type of the store's state.
  typealias State = [Key: AnyHashable]

  /// The state.
  private(set) var state: State = [:]

  /// The reducers transforming the state.
  private let reducers: [Key: SomeReducer<Message>]

  /// The listeners attached to this state.
  private var listeners: [AnyListener<Key, Message>?] = []

  /// Initializes with a set of reducers.
  ///
  /// This constructor accepts a list of reducers of the form `M, S -> Si`, and initializes a store
  /// whose state is a mapping `String -> S`, where `S` is the union of all `Si`.
  ///
  /// To the best of my knowledge, there is no way in Swift to build a type that safely maps a
  /// particular key to a particular type, without have all said keys known before hand (in which
  /// case, such a type would simply be a struct). This hinders static typing, as I have to erase
  /// the type of each specific part of the store. Specifically, `S` as to be typed with `Any` and
  /// some type checking has to be performed at runtime to properly dispatch messages.
  ///
  /// However, if the set of reducers for which a store is built was pre-processed, we could build
  /// the `reducers` and `state` properties as a struct. Not only would this preserve all types, it
  /// would also allow message dispatching to be implemented statically.
  init(_ mapping: (key: Key, to: SomeReducer<Message>)...) {
    // Register all reducers.
    var reducers: [Key: SomeReducer<Message>] = [:]
    for pair in mapping {
      reducers[pair.key] = pair.to
    }
    self.reducers = reducers

    // Initialize the state.
    self.state = reducers.mapValues { return $0.initialState }
  }

  /// Dispatches the given message to the appropriate reducer(s), potentially updating the state.
  mutating func dispatch(message: Message) {
    var didChange = false
    for (key, reducer) in reducers {
      if let newState = reducer.reduce(message: message, in: state[key]!) {
        // This is not perfectly correct, as colliding hashes will register as a state update.
        // Unfortunately, implementing a proper equality is difficult because state types are
        // erased. Furthermore, as we do not constrain states to be heap allocated objects (which
        // is likely appropriate w.r.t. performances), we can't rely on pointer equality neither.
        if newState.hashValue != state[key]!.hashValue {
          state[key] = newState
          didChange = true
        }
      }
    }

    if didChange {
      for listener in listeners where listener != nil {
        listener!.callback(store: &self)
      }
    }
  }

  /// Attaches a listener to this store.
  @discardableResult mutating func attach<L>(listener: L) -> Int
    where L: Listener, L.StateKey == Key, L.Message == Message
  {
    listeners.append(AnyListener(listener))
    return listeners.count - 1
  }

  /// Detaches a listener from this store.
  mutating func detach(listenerID: Int) {
    listeners[listenerID] = nil
  }

}
