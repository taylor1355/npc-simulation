# NPC Simulation Platform Business Plan
## Steam Distribution + Distributed Compute Model

**Document Status:** Final  
**Last Updated:** December 26, 2024  
**Author:** Development Team  

---

## Executive Summary

This business plan outlines the commercialization strategy for a multiplayer NPC simulation platform that enables large-scale AI societies through distributed compute and Steam distribution. The platform transforms the current single-player NPC simulation into a collaborative environment where players can observe and nurture authentic AI behaviors at unprecedented scale.

### Core Value Proposition
- **Authentic AI Societies:** NPCs with sophisticated memory systems, relationship dynamics, and emergent social behaviors
- **Unprecedented Scale:** 100-1000+ NPCs per world through distributed player compute contributions
- **Open-Source AI Customization:** Full NPC brain module available for deep modification and experimentation
- **Accessible Technology:** Complex AI simulation made approachable through Steam distribution and transparent pricing
- **Collaborative Observation:** Shared worlds where players witness emergent AI behaviors together

### Business Model Summary
- **Primary Revenue:** Steam game sales ($20-30) + in-game compute currency (10-15% markup on API tokens)
- **Distribution:** Steam Early Access launch with gradual multiplayer feature rollout
- **Target Market:** Simulation game enthusiasts, AI researchers, modding communities, and content creators
- **Financial Target:** $375K+ annual revenue by Year 2 through sustainable, scalable operations

---

## 1. Product Overview

### 1.1 Current Development Status

**MVP Foundation (Completed):**
- Godot-based 2D simulation with Sims-like gameplay mechanics
- Four core NPC needs: hunger, hygiene, fun, energy with decay systems
- Sophisticated MCP server architecture for AI decision-making
- Component-based interaction system with multi-party support
- Event-driven architecture separating simulation from AI logic
- Basic household items: beds, showers, fridges, ovens, food items

**Near-Term Roadmap (Next 6 months):**
- NPC-to-NPC conversation system with memory integration
- Simulated item interactions using LLM-enhanced physics
- Advanced memory maintenance with daily/weekly/monthly consolidation
- Container systems, cooking mechanics, and item mixing
- Enhanced AI observation systems with multimodal input support

### 1.2 Multiplayer Architecture Vision

**SpacetimeDB Integration:**
- Migration from local state management to distributed database-driven simulation
- Real-time state synchronization across multiple clients via WebSocket
- Player-contributed compute through automatically spawned MCP servers
- Token-based fairness system for NPC control allocation
- Scalable architecture supporting 100-1000+ NPCs per world

**Technical Advantages:**
- Sub-100μs transaction latency for responsive multiplayer experience
- WebAssembly-based reducers for efficient server-side logic
- Built-in real-time subscriptions eliminating custom networking code
- Atomic transaction model perfect for interaction bidding systems

### 1.3 Unique Market Position

**Differentiation from Existing AI Gaming:**
- **Scale:** 10-50x more NPCs than current AI gaming implementations
- **Authenticity:** Genuine AI societies vs. scripted NPCs with AI dialogue
- **Customizability:** Open-source NPC brain module vs. closed proprietary AI systems
- **Emergence:** Unpredictable social dynamics vs. predetermined storylines
- **Collaboration:** Shared observation of AI behaviors vs. isolated single-player experiences

**Competitive Advantages:**
- Three-tier architecture (Controller-Client-Backend) enables modular AI backends
- Open-source NPC module creates vibrant modding ecosystem and community innovation
- Distributed compute model scales economically vs. centralized server costs
- Component-based design allows rapid addition of new interaction types
- Event-driven architecture supports complex multi-party coordination

---

## 2. Business Model

### 2.1 Revenue Streams

**Primary Revenue Sources:**

1. **Steam Game Sales**
   - Initial purchase price: $20-30
   - Early Access launch strategy for community building
   - Steam handles payment processing, distribution, and user management

2. **In-Game Compute Currency ("Compute Coins")**
   - Transparent 10-15% markup on API token costs
   - Bulk purchase discounts and subscription options
   - Freemium model with 1,000 free tokens monthly per player

**Revenue Stream Breakdown:**
```
Game Sales (Year 2): 10,000 copies × $25 avg × 70% (after Steam) = $175,000
Compute Sales (Year 2): 2,000 active users × $12 avg monthly × 12 months = $288,000
Total Year 2 Revenue: ~$463,000
```

### 2.2 Pricing Strategy

**Compute Coin Pricing:**
- Base Rate: $0.0011 per token (vs. $0.001 OpenAI direct cost)
- Bulk Discounts: 25% bonus tokens on $20+ purchases, 50% bonus on $50+
- Monthly Subscriptions: $10/month for 10,000 tokens (recurring revenue)
- Free Tier: 1,000 tokens monthly (supports 2 NPCs for 1 day)

**Pricing Philosophy:**
- Complete transparency about costs vs. platform fees
- Minimal markup justified by convenience and integration value
- Volume incentives to encourage larger NPC populations
- Free tier enables experimentation and community growth

### 2.3 Player Economy Design

**Distributed Compute Integration:**
- Players can contribute their own API keys via client-spawned MCP servers
- Compute contributors earn tokens proportional to their contribution
- Creates player-to-player economy with platform taking small transaction fees
- Reduces platform compute costs while rewarding technically sophisticated users

**Token Allocation System:**
- Daily token output determines NPC control allocation
- Automatic load balancing based on player contribution and reliability
- Graceful fallback to platform-provided compute when player compute unavailable
- Performance-based multipliers reward reliable contributors

---

## 3. Technical Architecture

### 3.1 Current Architecture Foundation

**Three-Tier System:**
- **Controller (Godot):** Manages NPC physical simulation and state machines
- **Client (GDScript + C#):** Handles MCP communication and observation gathering
- **Backend (MCP Servers):** Provides AI decision-making via LLM APIs

**Key Technical Assets:**
- Robust event-driven architecture with 15+ event types
- Component-based entity system with PropertySpec type safety
- Open-source NPC brain module enabling deep AI customization and research
- Sophisticated interaction bidding system supporting multi-party coordination
- Vision system using Area2D for efficient entity detection
- Needs management with configurable decay rates and effects

### 3.2 SpacetimeDB Migration Strategy

**Phase 1: State Management Migration (6-8 weeks)**
- Convert NPC state, needs, and positions to SpacetimeDB tables
- Replace EventBus with SpacetimeDB reducer calls
- Implement WebSocket-based client synchronization
- Maintain single-player functionality during transition

**Phase 2: Multiplayer Foundation (4-6 weeks)**
- Add player authentication and session management
- Implement multi-client state coordination
- Create spectator mode for non-contributing players
- Develop real-time camera sharing and coordination

**Phase 3: Distributed Compute (8-10 weeks)**
- Implement token-based NPC assignment algorithm
- Create MCP server health monitoring and failover
- Add compute contribution tracking and validation
- Develop player economy and token marketplace
- Open-source NPC brain module with modding framework and documentation

**Technical Risk Mitigation:**
- Gradual migration preserving existing functionality
- Comprehensive fallback to centralized compute when needed
- Modular architecture enabling component-by-component testing
- Extensive use of SpacetimeDB's atomic transaction guarantees

### 3.3 Scaling Characteristics

**Performance Targets:**
- Support 100-1000 NPCs per world with <500ms state sync latency
- Handle 10-50 simultaneous players per world
- Maintain <5 second average NPC decision response times
- Achieve 99.9% uptime through SpacetimeDB infrastructure

**Horizontal Scaling:**
- World sharding for 1000+ NPC simulations
- Inter-module communication for cross-world events
- Regional deployment for latency optimization
- Automated load balancing based on player geography

---

## 4. Financial Projections

### 4.1 Revenue Model

**Year 1 (Early Access Launch):**
- Game Sales: 2,000 copies × $20 × 70% = $28,000
- Compute Sales: 500 users × $8 monthly avg × 6 months = $24,000
- **Total Year 1 Revenue: $52,000**

**Year 2 (Full Launch + Features):**
- Game Sales: 10,000 copies × $25 × 70% = $175,000
- Compute Sales: 2,000 users × $12 monthly avg × 12 months = $288,000
- **Total Year 2 Revenue: $463,000**

**Year 3 (Mature Platform):**
- Game Sales: 15,000 copies × $25 × 70% = $262,500
- Compute Sales: 4,000 users × $15 monthly avg × 12 months = $720,000
- Platform Fees: 5% of $200,000 player-to-player compute trades = $10,000
- **Total Year 3 Revenue: $992,500**

### 4.2 Cost Structure

**Development Costs:**
- Solo developer salary equivalent: $80,000 annually
- SpacetimeDB hosting: $6,000-24,000 annually (scales with usage)
- Steam platform fees: 30% of all game sales
- API token costs: 85-90% of compute currency revenue (10-15% markup)

**Operational Costs (Year 2):**
- SpacetimeDB hosting: ~$12,000
- Steam fees: $52,500 (30% of $175,000)
- Token costs: ~$245,000 (85% of $288,000)
- Development/infrastructure: $20,000
- **Total Year 2 Costs: $329,500**

**Net Profit Projections:**
- Year 1: $52,000 - $35,000 = $17,000 (33% margin)
- Year 2: $463,000 - $329,500 = $133,500 (29% margin) 
- Year 3: $992,500 - $650,000 = $342,500 (35% margin)

### 4.3 Unit Economics

**Customer Lifetime Value (2-year projection):**
- Average player: $25 game purchase + $144 compute spending = $169 LTV
- Heavy users (20%): $25 game + $600 compute spending = $625 LTV
- Light users (60%): $25 game + $60 compute spending = $85 LTV
- Free users (20%): $25 game only = $25 LTV

**Customer Acquisition Cost:**
- Organic Steam discovery: ~$0 (no paid marketing)
- Word-of-mouth referrals: ~$0
- Content creator showcases: Token gifting costs (~$5 per acquired user)

---

## 5. Operational Model

### 5.1 Solo Developer Approach

**Core Advantages:**
- No team coordination overhead or salary costs
- Rapid decision-making and feature iteration
- Direct connection to community feedback
- Minimal operational complexity and fixed costs

**Operational Philosophy:**
- Focus on core value: authentic AI behavior development
- Leverage existing platforms (Steam, SpacetimeDB) for infrastructure
- Avoid enterprise sales complexity in favor of simple B2C model
- Maintain lean operations that scale naturally with user growth

### 5.2 Technology Stack Decisions

**Platform Choices:**
- **Steam Distribution:** Proven game distribution with built-in community features
- **SpacetimeDB:** Handles complex multiplayer state synchronization automatically
- **Godot Engine:** Open-source, flexible, and excellent for 2D simulation games
- **MCP Protocol:** Standardized AI agent communication with growing ecosystem
- **Open-Source NPC Module:** Enables community-driven AI innovation and customization

**Operational Benefits:**
- Steam handles payments, distribution, user management, and customer support
- SpacetimeDB manages hosting, scaling, and database operations
- MCP servers run on player hardware, reducing infrastructure costs
- Open-source NPC module reduces development burden while building community
- Minimal custom infrastructure required beyond game development

### 5.3 Community Management

**Sustainable Community Approach:**
- Steam forums and workshop for community discussion and AI behavior mod sharing
- Discord server for real-time player coordination and modding support
- GitHub for open-source NPC module and community AI contributions
- Transparent development blog for feature updates and AI research insights

**Community Value Creation:**
- Player-contributed compute creates investment in platform success
- Open-source NPC brain module enables AI researchers and modders to innovate
- Shared worlds with custom AI behaviors generate collaborative experiences
- Technical transparency builds trust with sophisticated user base
- Community-created AI personalities and behaviors expand platform value

---

## 6. Risk Analysis

### 6.1 Technical Risks

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|-------------------|
| SpacetimeDB Performance Issues | Medium | High | Implement world sharding, maintain traditional fallback option |
| Player Compute Unreliability | High | Medium | Commercial API backup, graceful degradation, reputation system |
| Complex Migration Challenges | Medium | High | Gradual phase-by-phase migration, extensive testing |
| API Cost Fluctuations | Medium | Medium | Transparent pricing that adjusts with provider costs |

### 6.2 Market Risks

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|-------------------|
| Limited Market Interest | Low | High | Strong single-player foundation, organic growth through compelling content |
| Competitive Response | Medium | Medium | Focus on unique distributed compute model and authentic AI behavior |
| Steam Policy Changes | Low | High | Diversified revenue through compute sales, platform-agnostic architecture |
| AI Technology Shifts | Medium | Low | Modular backend supports multiple AI providers and technologies |

### 6.3 Business Model Risks

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|-------------------|
| Player Reluctance to Pay for Compute | Medium | High | Freemium model, transparent pricing, clear value demonstration |
| Insufficient Player Retention | Medium | High | Focus on emergent content, community building, regular updates |
| Scaling Infrastructure Costs | Low | Medium | Distributed compute model scales costs with revenue |
| Solo Developer Limitations | High | Medium | Prioritize core features, leverage existing platforms, avoid feature creep |

---

## 7. Success Metrics and Milestones

### 7.1 Key Performance Indicators

**Technical Metrics:**
- Average concurrent NPCs per world: Target 100-500 by Year 2
- State synchronization latency: <500ms target
- Player session duration: Target 45+ minutes average
- System uptime: 99.9% availability target

**Business Metrics:**
- Monthly Active Users: Target 2,000 by Year 2
- Average Revenue Per User: Target $12/month for compute spenders
- Customer Lifetime Value: Target $169 over 2 years
- Compute token utilization: Target 80% of purchased tokens used

**Community Metrics:**
- Player retention: 70% month-over-month retention target
- User-generated content: Steam Workshop submissions and ratings
- Community engagement: Discord activity and forum participation
- Word-of-mouth growth: Referral traffic and viral coefficient

### 7.2 Development Milestones

**Year 1 Milestones:**
- Q1: Complete single-player feature set, begin SpacetimeDB migration
- Q2: Steam Early Access launch with basic multiplayer features
- Q3: Distributed compute system implementation
- Q4: Token economy and player marketplace launch

**Year 2 Milestones:**
- Q1: 100-NPC world demonstrations, content creator partnerships
- Q2: Advanced AI features (memory maintenance, complex conversations)
- Q3: Full platform feature set, scaling to 1000+ concurrent users
- Q4: Platform maturity, community-driven content creation

**Year 3 Milestones:**
- Q1: 1000-NPC simulations, advanced emergent behaviors
- Q2: Platform ecosystem with community modifications and extensions
- Q3: International expansion and localization
- Q4: Long-term sustainability and growth planning

---

## 8. Conclusion

This business plan outlines a sustainable path to commercialize advanced NPC simulation technology through Steam distribution and ethical compute resale. The model balances revenue generation with community trust, technical innovation with operational simplicity, and ambitious vision with practical execution.

### Key Success Factors

1. **Technical Excellence:** Maintaining focus on authentic AI behavior and emergent social dynamics
2. **Community Trust:** Transparent pricing and ethical business practices with sophisticated user base
3. **Operational Efficiency:** Leveraging existing platforms to minimize complexity and overhead
4. **Sustainable Growth:** Revenue model that scales naturally with user engagement and platform value

### Strategic Vision

The platform positions itself as foundational infrastructure for AI-driven entertainment, creating a new category of collaborative AI observation and simulation. By combining sophisticated AI research with accessible gaming interfaces and open-source AI customization, the platform democratizes both access to large-scale AI simulation and the ability to innovate within AI behavior systems.

The open-source NPC brain module transforms the platform from a closed simulation into a research and experimentation environment where AI researchers, modders, and enthusiasts can contribute novel behaviors, memory systems, and social dynamics. This creates a virtuous cycle where community innovation enhances platform value for all users.

The distributed compute model not only solves technical scaling challenges but creates a unique community where players become stakeholders in the platform's success, fostering organic growth and long-term sustainability that supports continued innovation in authentic AI behavior systems.

---

**Document Revision History:**
- v1.0 - Initial business plan (December 26, 2024)
- v1.1 - TBD - Post-implementation learnings
- v2.0 - TBD - Market validation updates