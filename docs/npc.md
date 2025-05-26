# NPC System

## Overview
The NPC system implements real-time decision making through a three-tier architecture that separates simulation from decision making. The system is designed to be backend-agnostic, allowing for different decision making implementations while maintaining consistent behavior and interfaces.

The system follows an event-driven architecture where NPCs observe their environment, send these observations to a decision-making backend, and execute the resulting actions. This separation allows for flexible AI implementations while keeping the core simulation logic consistent.

Core components:
- **Controller**: The main simulation layer that manages NPC state and executes actions
- **Client**: A communication layer that handles backend interaction and caches responses
- **Backend**: A pluggable decision making system (currently using a local mock implementation)

## Core Components

### Controller (npc_controller.gd)
The controller manages the NPC's physical presence in the world, its interaction with the environment, and the execution of actions. It runs on a fixed update cycle to gather observations and make decisions (delegated to the client/backend). This component forms the core of the simulation layer for an individual NPC.

```
Key Features:
├── Decision Making
│   ├── Interval: 3.0 seconds (configurable)
│   └── Event-driven updates via client layer
├── Movement Control
│   ├── Pathfinding integration
│   ├── Destination management
│   └── Movement locking
├── Interaction Management
│   └── Handles `InteractionRequest` lifecycle with items
└── Vision System Integration
    └── Uses `VisionManager` to perceive items
```
The `NpcController` is also responsible for instantiating and managing the `NeedsManager` for the NPC.

### Need System
The NPC Need System simulates basic physiological and psychological requirements that drive NPC behavior. Each NPC has a set of needs that decay over time, creating internal pressure for the NPC to perform actions or interact with items that can satisfy these needs.

**Core Concepts & Components:**

*   **Need Types:** The fundamental needs are defined as an enumeration. Currently, these include:
    *   `HUNGER`
    *   `HYGIENE`
    *   `FUN`
    *   `ENERGY`
    These are defined in **`Needs` (`src/field/npcs/needs.gd`)**, which also provides utility functions for mapping enum values to display names (e.g., "hunger") and for serializing/deserializing need data.

*   **Need Values & Decay:**
    *   Each need has a numerical value, typically ranging from `0` to `100`.
    *   Needs decay over time at a configurable rate (e.g., 1-2 units per second, often randomized per NPC for variation).

*   **`NeedsManager` (`src/field/npcs/needs_manager.gd`):**
    *   Each `NpcController` owns an instance of `NeedsManager`.
    *   This manager is responsible for:
        *   Storing the current values of all needs for that specific NPC.
        *   Processing the decay of needs each frame.
        *   Providing methods (`update_need()`) to modify need values (e.g., when an item is consumed).
        *   Emitting a local `need_changed(need_name: String, new_value: float)` signal when a need's value is updated.

*   **`NpcController` Integration:**
    *   The `NpcController` initializes its `NeedsManager`
    *   It includes the current need values (obtained from `NeedsManager`) in the observation data sent to the decision-making backend.
    *   It connects to the `NeedsManager.need_changed` signal and, upon receiving it, dispatches a global **`NpcEvents.NeedChangedEvent`** via `FieldEvents`.

*   **`NEED_CHANGED` Event:**
    *   This global event (`NpcEvents.NeedChangedEvent`, detailed in `docs/events.md`) is crucial for other systems to react to an NPC's changing needs.
    *   It carries:
        *   `npc`: The `Gamepiece` instance of the NPC whose need changed.
        *   `need_id`: The string name of the need (e.g., "hunger").
        *   `new_value`: The updated floating-point value of the need.
    *   The UI system, for example, listens for this event to update need display bars.

This system ensures that an NPC's internal state (its needs) influences its behavior through the decision-making process and that changes to this state are communicated effectively throughout the game.

### Client Layer
The Client Layer serves as the interface between the NPC simulation logic (in GDScript) and the external MCP (Model Context Protocol) backend. It's responsible for abstracting the complexities of network communication, data serialization, and connection management. This layer is composed of GDScript and C# components.

**GDScript Facade (mcp_npc_client.gd)**
This script is the primary entry point for other GDScript parts of the game (like `NpcController`) to interact with the NPC's decision-making backend. It delegates calls to the C# layer.
```
Responsibilities (mcp_npc_client.gd):
├── API Abstraction:
│   └── Provides high-level methods (create_npc, process_observation, etc.)
├── Request Orchestration:
│   ├── Manages request IDs and callbacks for asynchronous operations
│   └── Handles basic retry logic
├── Data Formatting:
│   └── Utilizes EventFormatter for preparing observation data
└── Signal Aggregation:
    └── Connects to and forwards signals from the C# layer (McpSdkClient.cs)
```

**C# MCP Bridge (McpSdkClient.cs)**
This is a Godot Node written in C#. It acts as a direct bridge between GDScript calls from `mcp_npc_client.gd` and the C# MCP service proxy.
```
Responsibilities (McpSdkClient.cs - Godot Node):
├── GDScript Interoperability:
│   ├── Exposes methods callable from mcp_npc_client.gd
│   └── Emits Godot signals (RequestCompleted, RequestError) back to GDScript
├── Data Marshalling:
│   └── Converts Godot data types (e.g., Godot.Collections.Dictionary) to C# native types and vice-versa
├── Service Proxy Usage:
│   └── Instantiates and delegates calls to McpServiceProxy.cs
└── Error Handling:
    └── Catches exceptions from the service proxy and translates them into error signals
```

**C# Service Proxy (McpServiceProxy.cs)**
This pure C# class encapsulates all direct interactions with the ModelContextProtocol SDK. It manages the connection lifecycle and makes the actual calls to the MCP server.
```
Responsibilities (McpServiceProxy.cs - Pure C#):
├── Connection Lifecycle Management:
│   ├── Establishes and maintains the connection to the MCP server (via IMcpClient)
│   ├── Handles asynchronous connection logic, including retries and timeouts internally
│   └── Provides a robust way to get a connected IMcpClient instance
├── MCP SDK Abstraction:
│   └── Wraps IMcpClient methods (CallToolAsync, ListToolsAsync)
├── Thread Safety:
│   └── Manages concurrent access to connection resources if necessary (e.g., using locks)
└── Status Events (Optional):
    └── Can emit C# events for connection status changes (Connected, Disconnected)
```
This layered client architecture separates concerns: `mcp_npc_client.gd` for Godot integration, `McpSdkClient.cs` for C#/GDScript bridging and data marshalling, and `McpServiceProxy.cs` for robust MCP SDK interaction and connection management.

The interaction flow can be visualized as:
```
[NpcController (GDScript)]
       │
       └─ calls methods on ──> [mcp_npc_client.gd (GDScript Facade)]
                                     │
                                     └─ delegates to ──> [McpSdkClient.cs (C# Godot Node)]
                                                              │
                                                              └─ uses ──> [McpServiceProxy.cs (Pure C#)]
                                                                               │
                                                                               └─ interacts with ──> [MCP SDK/Server]
```

### Event System (npc_event.gd)
Events form the core communication mechanism within the NPC system, providing a standardized way to track state changes and trigger responses. This event-driven approach enables loose coupling between components and provides a clear audit trail of system behavior.

```
Event Types:
├── Interaction Events
│   ├── REQUEST_PENDING
│   ├── REQUEST_REJECTED
│   ├── STARTED
│   ├── CANCELED
│   └── FINISHED
├── OBSERVATION
└── ERROR

Event Structure:
├── timestamp: float (unix time)
├── type: Type (enum)
└── payload: Dictionary
```

Events are used to track interaction lifecycles and capture environmental observations. The payload structure varies by event type but always includes relevant context for decision making.

### Action System (npc_response.gd)
Actions represent the decisions made by the backend, translated into concrete behaviors the controller can execute. Each action type defines a specific operation with its own parameters and validation rules, providing a clear interface between decision making and execution.

```
Actions:
├── MOVE_TO: Path to location
├── INTERACT_WITH: Interact with an item
├── WANDER: Random movement
├── WAIT: Stay idle
├── CONTINUE: Maintain state
└── CANCEL_INTERACTION: Stop current interaction

Response Structure:
├── status: SUCCESS/ERROR
├── action: Action enum
└── parameters: Dictionary
```

The controller executes these actions through the appropriate systems (movement, interaction, etc). Failed actions trigger new observation events to get updated decisions.

## Communication Flow
### Decision Cycle
The decision cycle runs continuously, with the controller gathering observations and executing actions. The client manages the flow of information between components and ensures proper error handling.

```
Controller                 Client                    Backend
    │                        │                         │
    ├─ Update needs ─────────┤                         │
    │  (decay over time)     │                         │
    │                        │                         │
    ├─ Get visible items ────┤                         │
    │  (via vision system)   │                         │
    │                        │                         │
    ├─ Create observation ───┼─── mcp_npc_client.gd ───┼─── McpSdkClient.cs ───┼─── McpServiceProxy.cs ─── Forward request ────>│
    │  (needs + items)       │    (Format & Call C#)   │  (Marshal & Call Proxy) │   (Connect & Call SDK)   │                         │
    │                        │                         │                         │                          │                         │
    │                        │                         │                         │                          │<── Return decision ─────┤
    │                        │                         │                         │                          │    (action to take)     │
    │                        │                         │                         │                          │                         │
    │<── Return action ──────┼<── Emit Godot Signal <───┼<── Return C# Task <─────┼<── Return C# Task <───────┤
    │                        │                         │                         │                          │                         │
    ├─ Execute action ───────┤                         │                         │                          │                         │
    │  (move/interact)       │                         │
    │                        │                         │
    ├─ Handle result ────────┼─── Report result ──────>│
    │  (success/failure)     │                         │
    v                        v                         v
```


### Interaction Flow
```
Start Interaction:
1. Controller creates request
2. Item validates request
3. If accepted:
   ├── Set current_interaction
   ├── Connect completion handler
   └── Log STARTED event
4. If rejected:
   ├── Log REJECTED event
   └── Trigger new decision

Cancel Interaction:
1. Create cancel request
2. If accepted:
   ├── Log CANCELED event
   ├── Clear interaction state
   └── Trigger new decision
3. If rejected:
   └── Log rejection reason
```

Interactions follow a request-response pattern with explicit state transitions. This ensures proper cleanup and maintains consistency between the NPC and item states.

## Backend Interface
The backend system is designed to be replaceable, requiring only a few key capabilities:

1. NPC Creation
   - Accept traits and initial memory
   - Return unique identifier

2. Observation Processing
   - Handle environment observations
   - Process interaction events
   - Return action decisions

3. State Management
   - Maintain NPC state
   - Handle cleanup on removal

The mock_backend/ directory contains a reference implementation using a state machine pattern, but this will eventually be replaced with a server-based implementation.
