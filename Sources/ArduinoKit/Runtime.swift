/// The runtime system.
///
/// This class represents the runtime system of the program. Its method `advance(ms:)` (resp.
/// `run(frequency:duration:)`) allows one to simulate the execution of an application for a
/// specific time interval (resp. repetition thereof).
class Runtime {

  private struct Timeout {
    let when: Millisecond
    let callback: () -> Void
  }

  private(set) var uptime: Millisecond = 0
  private var timeouts: [Timeout] = []

  var application: SomeApplication!

  init<App>(_ appConstructor: (Runtime) -> App) where App: Application {
    self.application = SomeApplication(appConstructor(self))
  }

  func run(frequency: Hertz, duration: Millisecond) {
    let delta = Int(1.0 / Double(frequency) * 1000.0)

    let start = uptime
    while uptime - start < duration {
      self.advance(ms: delta)
    }
  }

  func advance(ms: Millisecond = 1) {
    // Advance time.
    uptime += ms

    // Process the registered timeouts.
    let enabled = timeouts.drop(while: { $0.when > uptime })
    for timeout in enabled {
      timeout.callback()
    }
    timeouts.removeFirst(enabled.count)

    application.render()
  }

  func setTimeout(_ ms: Millisecond, callback: @escaping () -> Void) {
    let newTimeout = Timeout(when: uptime + ms, callback: callback)
    if let i = timeouts.firstIndex(where: { $0.when > newTimeout.when }) {
      timeouts.insert(newTimeout, at: i)
    } else {
      timeouts.append(newTimeout)
    }
  }

  func setTimer(_ ms: Millisecond, callback: @escaping () -> Void) {
    func handler() {
      callback()
      self.setTimeout(ms, callback: handler)
    }
    setTimeout(ms, callback: handler)
  }

}
