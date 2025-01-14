# Interaction System

## Core Components

### Base Interaction (interaction.gd)
- Defines available interactions
- Key properties:
  ```
  name: String (interaction type)
  description: String (user-facing)
  ```
- Signals:
  ```
  start_request: New interaction
  cancel_request: End interaction
  ```

### Request System (interaction_request.gd)
```
Properties:
├── interaction_name: String
├── request_type: RequestType
├── status: Status
├── npc_controller: NpcController
└── item_controller: ItemController

Signals:
├── accepted: Request approved
└── rejected(reason): Request denied

Enums:
├── RequestType:
│   ├── START: Begin interaction
│   └── CANCEL: End interaction
└── Status:
    ├── PENDING: Awaiting response
    ├── ACCEPTED: Request approved
    └── REJECTED: Request denied
```

## Key Features

### Request Flow
```
Start Interaction:
1. NPC calls create_start_request()
2. Request sent to item controller
3. Item validates request:
   - No current interaction
   - Valid interaction type
   - Conditions met
4. Item accepts/rejects
5. Signals emitted
6. State updated

Cancel Interaction:
1. Entity calls create_cancel_request()
2. Request processed
3. Cleanup performed
4. State reset
5. Signals emitted
```

### Integration Points
```
NPC Controller:
├── Initiates requests
├── Handles responses
├── Manages state
└── Handles cleanup

Item Controller:
├── Validates requests
├── Manages active state
├── Tracks interaction time
└── Emits completion
```

## Usage

### Creating Interactions
```gdscript
# Define interaction
var interaction = Interaction.new(
    "sit",           # Name
    "Sit in chair"   # Description
)

# Connect handlers
interaction.start_request.connect(_on_start_request)
interaction.cancel_request.connect(_on_cancel_request)
```

### Request Handling
```gdscript
# Start interaction
var request = interaction.create_start_request(
    npc_controller,
    {"duration": 5.0}  # Optional args
)

# Process request
if can_accept_request(request):
    request.accept()
else:
    request.reject("Already in use")

# Handle results
request.accepted.connect(func(): start_interaction())
request.rejected.connect(func(reason): handle_rejection())
```
