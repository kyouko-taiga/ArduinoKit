/// An application.
///
/// An application is the object that puts all things together (i.e. a store with its reducers and
/// listeners, together with a `render()` method that performs writing updates to the environment).
protocol Application {

  associatedtype StateKey: Hashable
  associatedtype Message

  /// The application's store
  var store: Store<StateKey, Message> { get set }

  /// Renders the updates on the environment.
  ///
  /// For a lack of a better name, `render()` is the method that is supposed to declaratively write
  /// information to the environment. This method is meant to be completely declarative, and __must
  /// not__ dispatch any message. Instead, one should use listeners to dispatch messages whose
  /// guards depends on the application's state.
  func render()

}

/// An opaque application.
struct SomeApplication {

  private let _render: () -> Void

  init<App>(_ application: App) where App: Application {
    self._render = application.render
  }

  func render() {
    _render()
  }

}
