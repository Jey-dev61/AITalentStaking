# AITalentStaking

A reputation-based staking system where AI developers stake tokens on their expertise in specific domains and build reputation through successful project completions.

## Features

- **Domain Expertise Staking**: Developers stake STX tokens on specific AI domains
- **Reputation System**: Build reputation through successful project completions
- **Project Marketplace**: Clients post projects requiring specific domain expertise
- **Stake Requirements**: Projects require minimum stake amounts to ensure quality
- **Automated Rewards**: Successful project completion increases reputation and pays rewards

## Supported AI Domains

- Machine Learning
- Computer Vision  
- Natural Language Processing
- Deep Learning
- Data Science

## Contract Functions

### Public Functions
- `initialize()` - Set up valid AI domains
- `create-profile()` - Create developer profile
- `stake-on-domain(domain, amount)` - Stake tokens on domain expertise
- `create-project(title, domain, stake-required, reward)` - Create project requiring domain expertise
- `accept-project(project-id)` - Accept project (requires sufficient stake)
- `approve-project(project-id)` - Approve completed project and distribute rewards

### Read-Only Functions
- `get-developer-profile(developer)` - Get developer's profile and stats
- `get-domain-stake(developer, domain)` - Get domain-specific stake and reputation
- `get-project(project-id)` - Retrieve project details
- `is-valid-domain(domain)` - Check if domain is supported

## Usage Flow

1. Developers create profiles with `create-profile()`
2. Developers stake on their expertise areas using `stake-on-domain()`
3. Clients create projects with `create-project()` specifying domain and stake requirements
4. Qualified developers accept projects with `accept-project()`
5. Upon completion, clients approve projects with `approve-project()`
6. Developers earn reputation points and STX rewards

## Reputation System

- Initial reputation: 100 points
- Successful project completion: +10 reputation points
- Reputation is tracked both globally and per domain

## Testing

Run tests using Clarinet:
```bash
clarinet test