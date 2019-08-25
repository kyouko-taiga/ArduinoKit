infix operator =>

// MARK:- Environment mockup

enum Environment {

  /// The state (open or closed) of each valve.
  static var valveStates: [ValveState] = [.open, .open]

  /// The water level in each tank.
  static var waterLevels = [0, 0]

  // Simulates the reading of the water level.
  static func readWaterLevel(tankID: Int) -> Int {
    if valveStates[tankID] == .open {
      waterLevels[tankID] += Int.random(in: 0 ..< 3)
    } else {
      waterLevels[tankID] = max(0, waterLevels[tankID] - Int.random(in: 0 ..< 3))
    }
    return waterLevels[tankID]
  }

}

// MARK:- Application declaration

/// Declares the application.
///
/// Note that this type has reference semantics, so that we can refer to a mutating `self` closures
/// created in its constructor.
class MonitorApplication: Application {

  /// A weak reference to the runtime system.
  unowned var runtime: Runtime

  var store: Store<MonitorStateKey, MonitorMessage>

  init(runtime: Runtime) {
    self.runtime = runtime

    // Create the application's store. Notice how reducers are instantiated to for each water tank.
    self.store = Store<MonitorStateKey, MonitorMessage>(
      .waterLevel(tankID: 0) => WaterLevel(tankID: 0),
      .waterLevel(tankID: 1) => WaterLevel(tankID: 1),
      .valveState(tankID: 0) => Valve(tankID: 0),
      .valveState(tankID: 0) => Valve(tankID: 1))

    // Register listeners to close the valve when the tanks overflow. Notice once again how these
    // are instantiated for each water tank.
    self.store.attach(listener: OverflowListener(tankID: 0))
    self.store.attach(listener: OverflowListener(tankID: 1))

    // Set a timer to actively read the water level every 100 millisecond.
    self.runtime.setTimer(100) {
      let levelInTank0 = Environment.readWaterLevel(tankID: 0)
      let levelInTank1 = Environment.readWaterLevel(tankID: 1)
      self.store.dispatch(message: .setWaterLevel(tankID: 0, level: levelInTank0))
      self.store.dispatch(message: .setWaterLevel(tankID: 1, level: levelInTank1))
    }
  }

  func render() {
    Environment.valveStates[0] = (store.state[.valveState(tankID: 0)] as! Valve.State).value
    if (store.state[.waterLevel(tankID: 0)] as! WaterLevel.State).value > 5 {
      print("\(runtime.uptime): warning: tank 0 is about to overflow")
    }

    Environment.valveStates[1] = (store.state[.valveState(tankID: 0)] as! Valve.State).value
    if (store.state[.waterLevel(tankID: 1)] as! WaterLevel.State).value > 5 {
      print("\(runtime.uptime): warning: tank 1 is about to overflow")
    }
  }

}

enum ValveState {

  case open, closed

}

enum MonitorStateKey: Hashable {

  case valveState(tankID: Int)
  case waterLevel(tankID: Int)

  static func => <R> (lhs: MonitorStateKey, rhs: R)
    -> (key: MonitorStateKey, to: SomeReducer<R.Message>)
    where R: Reducer
  {
    return (key: lhs, to: SomeReducer(rhs))
  }

}

enum MonitorMessage {

  case setWaterLevel(tankID: Int, level: Int)
  case setValveState(tankID: Int, state: ValveState)

}

struct WaterLevel: Reducer {

  struct State: Hashable {
    let value: Int
  }

  var tankID: Int

  init(tankID: Int) {
    self.tankID = tankID
  }

  func reduce(message: MonitorMessage, in state: State) -> State {
    switch message {
    case .setWaterLevel(tankID: tankID, let level):
      return State(value: level)
    default:
      return state
    }
  }

  static let initialState = State(value: 0)

}

struct Valve: Reducer {

  struct State: Hashable {
    let value: ValveState
  }

  var tankID: Int

  init(tankID: Int) {
    self.tankID = tankID
  }

  func reduce(message: MonitorMessage, in state: State) -> State {
    switch message {
    case .setValveState(tankID: tankID, let value):
      return State(value: value)
    default:
      return state
    }
  }

  static let initialState = State(value: .open)

}

struct OverflowListener: Listener {

  var tankID: Int

  init(tankID: Int) {
    self.tankID = tankID
  }

  func callback(store: inout Store<MonitorStateKey, MonitorMessage>) {
    if (store.state[.waterLevel(tankID: tankID)] as! WaterLevel.State).value > 8 {
      store.dispatch(message: .setValveState(tankID: tankID, state: .closed))
    }
  }

}

// MARK:- Model simulation

do {
  let runtime = Runtime(MonitorApplication.init)
  runtime.run(frequency: 10, duration: 10_000)
}
