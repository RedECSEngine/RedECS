# Getting Started with RedECS

> If you just want to dive into code asap and skip the manual, clone the [starter template](https://github.com/RedECSEngine/starter-template). 
> 
> Otherwise, let's take dive deeper before we resurface to try coding


## RedECS is an Entity Component System
The first thing you should probably understand, in some capacity, is an [Entity Component System](https://en.wikipedia.org/wiki/Entity_component_system). This is a pretty common concept in gaming and many engines so this tutorial will leave it to the reader to understand this in advance.

There are a lot of different ways to organise an ECS, in terms of order of operations of your code. That is, does the logic run "per entity, per component" or "per component system, per entity". In RedECS, it happens "per reducer", which by default closely resembles "per component system, per entity", but with more control for the more advanced.

RedECS separates your game state from the reducers that manipulate it. Because these reducers are composable with one another, you can completely control the order that there execute in and what parts of the game state they are allowed to manipulate. You can write reducers that only function with one component of your game state, or reducers that manipulate with your entire game state. That is what make this engine so composable.

## Anatomy of Game State

A very basic game state might looks like this

```swift
public struct GameState: RenderableGameState {
    public var entities: EntityRepository = .init()
    
    public var camera: [EntityId: CameraComponent] = [:]
    public var sprite: [EntityId: SpriteComponent] = [:]
    public var transform: [EntityId: TransformComponent] = [:]

    public init() {}
}

```

As you can see a RedECS Game State is primarily made up of an `EntityRepository` and a series of `Dictionary<EntityId:GameComponent>` by different key names where `GameComponent` is actually a specific Component that conforms to `GameComponent`

`GameComponent` inherits from `Codable & Equatable`, and you can expect the same from `EntityRepository` which means your whole game state is encodable at any time.

## Manipulating GameState

There are 2 fundamental ways to change your game state:

1. Time (deltas)
2. Actions

We will get to time in a moment, but Actions need a little more explaning first.

### Actions
There are 2 types of actions:

1. Game Acions
	- This will be all the actions your game defines as different inputs and events that occur which arent directly related to the passage of time. This can be used for user input, or even ways to break apart your code into smaller chuncks and communicate events across the application

2. System Actions
	- example: Add Entity, Destroy Entity, Add/Remove Component for Entity

### Reducers

Reducers are where all the magic happens. You might be wondering why it took so long to explain what they are, but they are like the cooking pot that mixes all the ingredients. If we showed you the pots before the ingredients it would make even less sense.

This is currently the pull protocol of `Reducer`

```swift
public protocol Reducer {
    associatedtype State: GameState
    associatedtype Action: Equatable
    associatedtype Environment

    func reduce(state: inout State, delta: Double, environment: Environment) -> GameEffect<State, Action>
    func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action>
    
    func reduce(state: inout State, entityEvent: EntityEvent, environment: Environment) -> GameEffect<State, Action> // Has default implementation to do nothing
}
```

#### Reducer Associated Types
We can see that a reducer has 3 key types: `State`, `Action`, and `Environment`. We have already discussed `State` and `Action`. `Environment` is not very relevant for the timebeing, but it is where rendering and resource management occur, which is different per platform. Your reducers dont touch `Environment` things dealing with these things, and this engine comes with defaults for all those needs.

#### Reducer functions

The most important reducer functions are `reduce(state:delta:environment:)` and `reduce(state:action:environment:)`. The third function is not needed unless you need to monitor "System Actions", like mentioned above.

You can see that one function is for manipulating state over time and the other is for manipulating state based on discrete actions. All functions return a `GameEffect<State, Action>`, which is a way for any delta or Action to trigger more effects; either Game Actions or System Actions.

### Game Effect

A simplification of the `GameEffect` enum looks like this:

```swift
public indirect enum GameEffect<State: GameState, LogicAction: Equatable> {
    case system(SystemAction<State>)
    case game(LogicAction)
    case many([Self])
    case none
    
    // ... Some other cases, not recommended for special reasons
}
```

Fundamentally it breaks down to these choices:

1. Do nothing
2. Create/Destroy an Entity, Or add/remove a component from an entity
3. Trigger another action
4. Do many of the above

While you have the opportunity to perform `#2` inside of your own reducer funcs by manipulating the game state this is **BAD PRACTICE** as it means that other reducers can't be informed of those changes. This could lead to artifacts in your state, such as if an entity were removed from the repository manually, preventing the destroy event from firiing to all reducers to perform some cleanup.

### The fundamental components of RedECS
Assuming that your want to render something with this engine, you will need 3 key components - `TransformComponent`, `SpriteComponent`, `CameraComponent`. Both cameras and sprites require a transform component to function. Your camera might be a separate entity with no sprite component, or it might be the component of a sprite, if you want camera follow behavior for your game.


## Let's get coding!
Clone the [starter template](https://github.com/RedECSEngine/starter-template) to continue this journey. Good luck and feel free to reach out with questions.

