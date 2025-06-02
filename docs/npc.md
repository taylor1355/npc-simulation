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
The controller manages the NPC's physical presence in the world, its interaction with the environment, and the execution of actions. It uses a `ControllerStateMachine` to manage its behavior based on decisions from the backend. The NPC's unique identifier (`npc_id`) is derived from its instance ID (`str(get_instance_id())`).

```
Key Features:
├── Decision Making Cycle (every `DECISION_INTERVAL` = 3.0s)
│   ├── Gathers observations (current needs, visible items via `VisionManager`, etc.)
│   ├── Sends observations to `NpcClientBase` implementation (e.g., `McpNpcClient`)
│   └── Receives actions and delegates to `ControllerStateMachine`
├── Movement Control
│   ├── Pathfinding integration (via `GamepieceController`)
│   ├── Destination management (`destination` property)
│   └── Movement locking (`movement_locked` property)
├── Interaction Management
│   ├── Holds `current_interaction` and `current_request`
│   └── Delegates `_on_interaction_accepted`, `_on_interaction_rejected`, `_on_interaction_finished` to current state in `ControllerStateMachine`
├── Vision System Integration
│   └── Uses `VisionManager` (`$VisionArea`) to perceive items
└── Needs Management
    └── Instantiates and manages `NeedsManager`
```

### Need System
The NPC Need System simulates basic physiological and psychological requirements that drive NPC behavior. Each NPC has a set of needs that decay over time, creating internal pressure for the NPC to perform actions or interact with items that can satisfy these needs.

**Core Concepts & Components:**

*   **`Needs` (`src/field/npcs/needs.gd`):** This class defines the fundamental need types and provides utility functions related to them.
    *   The core needs are defined in `enum Need { HUNGER, HYGIENE, FUN, ENERGY }`.
    *   It establishes `MAX_VALUE: float = 100.0` for all needs.
    *   It provides utility functions for mapping enum values to display names (e.g., `Needs.Need.HUNGER` to "hunger"), parsing string names back to enums, and for serializing/deserializing need data (e.g., `Dictionary[Needs.Need, float]` to `Dictionary[String, float]`) for backend communication or storage.

*   **`NeedsManager` (`src/field/npcs/needs_manager.gd`):** Each `NpcController` owns an instance of `NeedsManager`, which is responsible for:
    *   Storing the current values of all needs for that specific NPC (in `_needs: Dictionary[Needs.Need, float]`, initialized to `Needs.MAX_VALUE`).
    *   Processing the decay of needs each frame via `process_decay(delta_time: float)`, using a randomized decay rate (e.g., 1.0-2.0 units per second) set by the `NpcController` during initialization.
    *   Providing methods (`update_need(need: Needs.Need, delta: float)`) to modify need values (e.g., when an item is consumed), ensuring values are clamped between 0 and `Needs.MAX_VALUE`.
    *   Emitting a local `need_changed(need_name: String, new_value: float)` signal whenever a need's value changes.
    *   Providing helper methods like `get_all_needs() -> Dictionary[String, float]` (used for observation data) and `reemit_all_needs()` (useful for UI updates on focus).

*   **`NpcController` Integration:**
    *   Initializes its `NeedsManager`.
    *   Includes current need values (from `NeedsManager.get_all_needs()`) in observation data.
    *   Connects to `NeedsManager.need_changed`. When this local signal is received, `NpcController` emits its own `need_changed` signal and then dispatches a global event using `EventBus.dispatch(NpcEvents.create_need_changed(_gamepiece, need_name, new_value))`.

*   **`NEED_CHANGED` Event (Global):**
    *   Created by `NpcEvents.create_need_changed(gamepiece, need_name, new_value)`.
    *   Carries:
        *   `npc`: The `Gamepiece` instance of the NPC.
        *   `need_id`: The string name of the need (e.g., "hunger").
        *   `new_value`: The updated floating-point value.
    *   Used by systems like UI to react to need changes.

This system ensures that an NPC's internal state (its needs) influences its behavior through the decision-making process and that changes to this state are communicated effectively throughout the game.

### Client Layer
The Client Layer serves as the interface between the NPC simulation logic (in GDScript) and the external MCP (Model Context Protocol) backend. It's responsible for abstracting the complexities of network communication, data serialization, and connection management. This layer is composed of GDScript and C# components.

**GDScript Facade (`mcp_npc_client.gd` - Class `McpNpcClient`)**
This script extends `NpcClientBase` and is the primary GDScript entry point for `NpcController` to interact with the MCP backend. Its key responsibilities include:
*   Providing a GDScript-friendly API for NPC operations (like `create_npc`, `process_observation`, `cleanup_npc`, `get_npc_info`) to the rest of the game, abstracting the C# backend interaction.
*   Managing asynchronous requests to the C# layer using an inner `PendingRequest` class. This class orchestrates calls to the C# `_sdk_client` (e.g., `_sdk_client.CreateAgent(...)`) and handles callbacks upon completion or error.
*   Implementing retry logic for failed requests via `_retry_counts` and `_handle_request_error`.
*   Utilizing an `EventFormatter` (`_event_formatter`) to convert game events and NPC state (from the `NpcController`'s `event_log`) into a structured observation format suitable for the backend.
*   Listening to `RequestCompleted` and `RequestError` signals from the C# `_sdk_client` and translating them into appropriate game events (like `NpcClientEvents.ActionChosenEvent`) or emitting its own `error` signal.

**C# MCP Bridge (`McpSdkClient.cs` - Partial Class `McpSdkClient`)**
This is a Godot Node written in C#. It acts as a direct bridge between GDScript calls from `mcp_npc_client.gd` and the C# `McpServiceProxy`. Its main functions are:
*   Exposing methods (e.g., `CreateAgent`, `ProcessObservation`, `CleanupAgent`, `GetResource`, `ListTools`) that can be directly called from the GDScript `McpNpcClient`.
*   Handling data marshalling: It converts data structures between Godot's `Variant` types (like `Godot.Collections.Dictionary` and `Godot.Collections.Array`) and native C# types (like `Dictionary<string, object>` and `List<object>`) for interaction with the `McpServiceProxy`.
*   Instantiating and delegating the actual MCP communication tasks to an `McpServiceProxy` instance.
*   Emitting Godot signals (`RequestCompletedEventHandler` and `RequestErrorEventHandler`) back to the GDScript layer upon completion or failure of backend requests, providing the response data or error messages.
*   Includes basic error handling for exceptions caught from the `McpServiceProxy`, ensuring that errors are propagated back to the GDScript layer.
*   (Note: It uses an internal C# `PendingRequest` class for its own tracking of requests, which is distinct from the `PendingRequest` inner class defined in `mcp_npc_client.gd`.)

**C# Service Proxy (`McpServiceProxy.cs` - Class `McpServiceProxy`)**
This pure C# class encapsulates all direct interactions with the ModelContextProtocol SDK. It robustly manages the connection lifecycle and makes the actual calls to the MCP server. Key aspects include:
*   Managing the connection lifecycle to the MCP server. Its `EnsureConnectedClientAsync` method robustly establishes and maintains an active `IMcpClient` instance, handling initial connection (`ConnectInternalAsync` using `McpClientFactory`) and preventing redundant attempts by managing `_currentConnectionTask`.
*   Abstracting MCP SDK interactions by wrapping `IMcpClient` methods such as `CallToolAsync`, `ListToolsAsync`, and `ReadResourceAsync`.
*   Ensuring thread safety for connection state management using `lock (_lock)`.
*   Optionally, it can define C# events like `Connected`, `ConnectionFailed`, and `Disconnected` to signal connection status changes.

This layered client architecture separates concerns: `mcp_npc_client.gd` for Godot integration and high-level NPC logic, `McpSdkClient.cs` for C#/GDScript bridging and data marshalling, and `McpServiceProxy.cs` for robust MCP SDK interaction and connection management.

The interaction flow can be visualized as:
```
[NpcController (GDScript)]
       │
       └─ calls methods on ──> [mcp_npc_client.gd (GDScript Facade, uses EventFormatter)]
                                     │  (PendingRequest.execute() calls C# method)
                                     └─ delegates to ──> [McpSdkClient.cs (C# Godot Node)]
                                                              │
                                                              └─ uses ──> [McpServiceProxy.cs (Pure C#)]
                                                                               │
                                                                               └─ interacts with ──> [MCP SDK/Server]
```

### Event System (`npc_event.gd`)
The `NpcEvent` class (`src/field/npcs/npc_event.gd`) defines the structure for events that capture NPC interactions, observations, and errors. These events are primarily logged by the `NpcController` to build a history (`event_log`) which is then formatted by `EventFormatter` and sent to the decision-making backend as part of an NPC's observation.

*   **Structure:** Each `NpcEvent` includes:
    *   `timestamp`: Unix time of the event.
    *   `type`: An `NpcEvent.Type` enum value (see below).
    *   `payload`: A `Dictionary` containing event-specific data.

*   **Key Event Types (`NpcEvent.Type` enum):**
    *   `OBSERVATION`: A snapshot of the NPC's current state, perceived items, needs, controller state, and current interaction status. This is the main event type sent for decision making.
    *   Interaction Lifecycle Events: `INTERACTION_REQUEST_PENDING`, `INTERACTION_REQUEST_REJECTED`, `INTERACTION_STARTED`, `INTERACTION_CANCELED`, `INTERACTION_FINISHED`. These track the progress of an NPC's interaction with an item.
    *   `ERROR`: Indicates an error occurred during NPC processing.

*   **Creation:** Events are typically created using static factory methods on the `NpcEvent` class (e.g., `NpcEvent.create_observation_event(...)`, `NpcEvent.create_interaction_request_event(...)`), which help ensure consistent payload structures for different event types.

### Action System (`npc_response.gd` and `action.gd`)
The Action System defines the set of behaviors an NPC can be instructed to perform by the decision-making backend. These instructions are received by the `NpcController` and executed via its `ControllerStateMachine`.

*   **`Action.Type` (`src/field/npcs/action.gd`):** This enum defines all possible actions an NPC can take:
    *   `MOVE_TO`: Navigate to a specific cell.
    *   `INTERACT_WITH`: Engage with a specified item.
    *   `WANDER`: Move to a random valid location.
    *   `WAIT`: Remain idle for a period.
    *   `CONTINUE_ACTION`: Continue with the current ongoing action, if applicable (this allows the backend to explicitly state the NPC should continue its current task).
    *   `CANCEL_INTERACTION`: Stop the current interaction.

*   **`NpcResponse` (`src/field/npcs/npc_response.gd`):** This class structures the decision received from the backend. While the backend primarily communicates the chosen action and parameters through the `NpcClientEvents.ActionChosenEvent` (which is what the `NpcController` consumes), `NpcResponse` itself defines a standard structure that includes:
    *   `status`: An enum `Status { SUCCESS, ERROR }`.
    *   `action`: The chosen `Action.Type`.
    *   `parameters`: A `Dictionary` containing any data needed for that action (e.g., target item name for `INTERACT_WITH`).
    *   It also provides static factory methods like `create_success(...)` and `create_error(...)`, which are useful for mock backends or testing.

The `NpcController` listens for an `NpcClientEvents.ActionChosenEvent`. This event, triggered by the client layer after receiving a decision from the backend, contains the `action_name` (string) and `parameters` (Dictionary). The controller then passes this information to its `ControllerStateMachine` to handle the execution of the chosen action.

## Communication Flow
### Decision Cycle
The decision cycle runs continuously. The `NpcController` gathers observations, which are formatted and sent via the `NpcClientBase` implementation to the backend. The backend returns an action, which the controller's state machine executes.

```
NpcController              McpNpcClient (GDScript)     McpSdkClient (C#)       McpServiceProxy (C#)      Backend
    │ (Every 3s)             │                           │                       │                         │
    ├─ Update needs (decay) ─┤                           │                       │                         │
    │                        │                           │                       │                         │
    ├─ Get visible items ───►│                           │                       │                         │
    │  (via VisionManager)   │                           │                       │                         │
    │                        │                           │                       │                         │
    ├─ Create NpcEvent(OBSERVATION) ┐                     │                       │                         │
    │  (add to event_log)           │                     │                       │                         │
    │                        │                           │                       │                         │
    ├─ process_observation(event_log)─► (uses EventFormatter)─► CreateAgent/ProcessObs ─► CallToolAsync ─────► Forward request ────>│
    │                        │                           │      (Marshal data)         │ (Connect & Call SDK)│                         │
    │                        │                           │                           │                       │<── Return decision ─────┤
    │                        │                           │                           │                       │    (action to take)     │
    │                        │                           │                           │                       │                         │
    │◄── NpcClientEvents.ActionChosenEvent ◄─ Emit Godot Signal ◄─── Return C# Task ◄───── Return C# Task ◄───┤
    │    (from EventBus)  │                           │                           │                       │                         │
    │                        │                           │                           │                       │                         │
    ├─ state_machine.handle_action() ┐                   │                           │                       │                         │
    │  (executes move/interact etc.)│                   │                           │                       │                         │
    │                        │                           │                           │                       │                         │
    ├─ Handle result/state changes ┘                   │                           │                       │                         │
    │  (e.g., interaction finished)│                   │                           │                       │                         │
    v                        v                           v                       v                         v
```

### Interaction Flow
Interactions are managed by the `NpcController`'s current state within its `ControllerStateMachine`.
```
Start Interaction (Simplified):
1. NPC's current state (in ControllerStateMachine) decides to interact.
2. State creates an InteractionRequest.
3. State calls item_controller.request_interaction(request).
4. ItemController and its components validate the request.
5. If accepted by item:
   ├── ItemController emits request.accepted().
   ├── NPC's state (connected to request.accepted) handles acceptance:
   │   ├── Sets NpcController.current_interaction, NpcController.current_request.
   │   └── Logs NpcEvent.INTERACTION_STARTED (or similar via NpcEvents factory).
   │   └── Transitions to an "interacting" state.
6. If rejected by item:
   ├── ItemController emits request.rejected(reason).
   ├── NPC's state (connected to request.rejected) handles rejection:
   │   └── Logs NpcEvent.INTERACTION_REQUEST_REJECTED.
   │   └── Triggers new decision cycle in NpcController.

Cancel Interaction (Simplified):
1. NPC's current state (or NpcController) decides to cancel.
2. Creates a cancel InteractionRequest.
3. Item validates cancellation.
4. If accepted:
   ├── Logs NpcEvent.INTERACTION_CANCELED.
   ├── Clears NpcController.current_interaction, NpcController.current_request.
   └── Triggers new decision cycle.
5. If rejected (rare for cancel):
   └── Log reason.
```
Interaction lifecycle events (`REQUEST_PENDING`, `STARTED`, `FINISHED`, etc.) are created using `NpcEvent` factory methods and become part of the `event_log` for the backend.

## Backend Interface
The backend system, accessed via an `NpcClientBase` implementation (like `McpNpcClient`), needs to support:

1.  **NPC Creation/Agent Initialization:**
    *   Client Method: `McpNpcClient.create_npc(npc_id, traits, working_memory, ...)`
    *   Backend Tool: `create_agent` (called by `McpSdkClient`)
    *   Accepts: Agent ID, configuration (traits, initial memories).
    *   Returns: Confirmation of creation.

2.  **Observation Processing & Action Selection:**
    *   Client Method: `McpNpcClient.process_observation(npc_id, events)`
    *   Backend Tool: `process_observation` (called by `McpSdkClient`)
    *   Accepts: Agent ID, formatted observation string (from `EventFormatter`), list of available actions.
    *   Returns: Selected action (name and parameters).

3.  **NPC State Retrieval (Info):**
    *   Client Method: `McpNpcClient.get_npc_info(npc_id, ...)`
    *   Backend Resource: `agent://<npc_id>/info` (accessed by `McpSdkClient.GetResource`)
    *   Returns: NPC's current state (traits, working memory).

4.  **NPC Cleanup/Agent Removal:**
    *   Client Method: `McpNpcClient.cleanup_npc(npc_id)`
    *   Backend Tool: `cleanup_agent` (called by `McpSdkClient`)
    *   Accepts: Agent ID.
    *   Returns: Confirmation of cleanup.

The `src/field/npcs/mock_backend/` directory contains a reference GDScript implementation, while the primary flow assumes an MCP server backend accessed via the C# SDK.
