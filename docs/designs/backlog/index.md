# Feature Backlog

This directory contains design documents for features that are planned but not yet implemented. Each document provides a detailed technical design, rationale, and implementation plan.

## Backlog Features

### 1. [Sprite Layering System](sprite_layering_system.md)

**Status**: Design Phase  
**Priority**: High  
**Complexity**: Medium

A comprehensive solution to replace manual z-index management with a sprite layer system that enables natural furniture occlusion. This feature will:

- Fix the current bug where emoji states render behind other NPCs when sitting
- Enable complex furniture interactions (beds with sheets, showers, etc.)
- Eliminate z-index conflicts with Godot's Y-sorting system
- Provide a reusable component system for layered sprites

**Key Benefits**:
- Natural-looking furniture occlusion
- Extensible for new furniture types
- Component-based architecture
- Performance-optimized

---

## Adding New Backlog Items

When adding a new feature to the backlog:

1. Create a design document in this directory with a descriptive filename
2. Update this index with a brief summary
3. Include: status, priority, complexity, and key benefits
4. Follow the design document template used in existing documents

## Design Document Template

- **Problem Statement**: What issue does this solve?
- **Proposed Solution**: High-level approach
- **Design Goals**: What criteria define success?
- **Technical Design**: Detailed implementation plan
- **Benefits**: Why implement this feature?
- **Risks and Mitigation**: Potential issues and solutions
- **Alternatives Considered**: Other approaches evaluated