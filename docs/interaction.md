# Interaction System

## Core Components

### Base Interaction (interaction.gd)
```
Properties:
├── name: String
└── description: String

Signals:
├── start_request(request)
└── cancel_request(request)

Factory Methods:
├── create_start_request(npc, arguments)
└── create_cancel_request(npc, arguments)
```

### Request System (interaction_request.gd)
```
Properties:
├── interaction_name: String
├── request_type: RequestType
├── status: Status
├── npc_controller: NpcController
├── item_controller: ItemController
└── arguments: Dictionary

Enums:
├── RequestType
│   ├── START
│   └── CANCEL
└── Status
    ├── PENDING
    ├── ACCEPTED
    └── REJECTED

Signals:
├── accepted()
└── rejected(reason: String)
```

## Integration Flow

### Request Creation
```
1. Component defines interaction:
   var interaction = Interaction.new(
       "consume",
       "Consume this item"
   )

2. Register with controller:
   interactions[interaction.name] = interaction

3. Connect handlers:
   interaction.start_request.connect(_handle_start)
   interaction.cancel_request.connect(_handle_cancel)
```

### Request Processing
```
Start Flow:
1. NPC initiates:
   var request = interaction.create_start_request(
       self,  # NPC controller
       {}     # Optional arguments
   )

2. Item validates:
   if current_interaction == null:
       request.accept()
       # Setup state
   else:
       request.reject("In use")

3. Component handles:
   func _handle_start(request):
       if can_start():
           request.accept()
           setup_interaction()
       else:
           request.reject("Cannot start")

Cancel Flow:
1. NPC initiates cancel
2. Item validates state
3. Component cleans up
4. State reset
```

### State Management
```
Item Controller:
├── interactions: Dictionary
├── current_interaction: Interaction
├── interacting_npc: NpcController
└── interaction_time: float

Component:
├── Tracks specific state
├── Handles validation
├── Manages cleanup
└── Emits completion
```
