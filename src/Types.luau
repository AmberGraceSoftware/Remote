--!strict

export type Connection = RBXScriptConnection
export type Unsubscribe = () -> ()
export type Event = {
    ConnectServer: (
        self: Event,
        callback: (player: Player, ...unknown) -> ()
    ) -> Connection,
    ConnectClient: (self: Event, callback: (...any) -> ()) -> Connection,
    FireServer: (self: Event, ...any) -> (),
    FireClient: (self: Event, player: Player, ...any) -> (),
    FireAllClients: (self: Event, ...any) -> (),
    FireExceptClient: (self: Event, player: Player, ...any) -> (),
    Destroy: (self: Event) -> (),
}
export type Function = {
    Invoke: (self: Event, ...any) -> any,
    OnInvoke: (
        self: Event,
        callback: (player: Player, ...unknown) -> any
    ) -> (),
    Destroy: (self: Event) -> (),
}
export type State<T = any?> = {
    Get: (self: State<T>) -> T,
    Set: (self: State<T>, newValue: T) -> (),
    SetFor: (self: State<T>, player: Player, newValue: T) -> (),
    SetTop: (self: State<T>, newValue: T) -> (),
    ClearFor: (self: State<T>, player: Player) -> (),
    GetFor: (self: State<T>, player: Player) -> T,
    Subscribe: (
        self: State<T>,
        listener: (newValue: T) -> (),
        immediatelyCallListener: boolean?
    ) -> Unsubscribe,
    SubscribeFor: (
        self: State<T>,
        player: Player,
        listener: (newValue: T) -> (),
        immediatelyCallListener: boolean?
    ) -> Unsubscribe,
    Destroy: (self: State<T>) -> (),
}
export type Namespace = {
    Namespace: (prefix: string) -> Namespace,
    Event: (key: string) -> Event,
    Function: (key: string) -> Function,
    State: <T>(key: string, placeholderValue: T) -> State<T>,
}

return nil
