# VortexDAO - Decentralized Autonomous Organization

VortexDAO is a comprehensive governance platform built on the Stacks blockchain, enabling community-driven decision making through proposal creation, voting, and treasury management.

## Features

- **Proposal System**: Create and manage community proposals with detailed descriptions
- **Token-Based Voting**: Vote on proposals using VORTEX governance tokens
- **Treasury Management**: Automated execution of approved funding proposals
- **Delegation System**: Delegate voting power to trusted community members
- **Administrative Controls**: Configurable governance parameters and emergency controls
- **Enhanced Security**: Multi-layered validation and access controls

## Architecture

### Core Components

#### Governance Token (VORTEX)
- Fungible token used for voting power
- Balance determines proposal submission eligibility
- Required for participating in governance decisions

#### Proposal Management
- Structured proposal creation with metadata support
- Configurable voting periods and execution delays
- Automatic quorum validation and execution

#### Voting System
- Token-weighted voting mechanism
- Support for delegation of voting power
- Comprehensive vote tracking and analytics

### Proposal Lifecycle

1. **Creation**: Community members create proposals with required token balance
2. **Voting Period**: Token holders vote during the defined voting window
3. **Quorum Check**: Proposals must meet minimum participation thresholds
4. **Execution**: Approved proposals are automatically executed after delay period

## Usage

### Creating Proposals

```clarity
(create-motion "Proposal Title" 
               "Detailed description of the proposal" 
               1000000000  ;; Amount in microSTX
               'SP123...   ;; Recipient address
               10          ;; Execution delay in blocks
               (some "Additional metadata"))
```

### Voting on Proposals

```clarity
(cast-ballot 1           ;; Proposal ID
             100000000   ;; Vote amount
             true)       ;; Support (true) or oppose (false)
```

### Delegation

```clarity
(assign-delegate 'SP456...)  ;; Delegate voting power to another address
```

## Administrative Functions

### Governance Parameter Updates
- Minimum proposal threshold
- Voting period duration
- Quorum requirements
- Execution delays

### Emergency Controls
- Toggle proposal submission
- Toggle voting functionality
- Emergency pause mechanisms

## Security Features

- **Input Validation**: Comprehensive validation of all user inputs
- **Access Control**: Role-based permissions for administrative functions
- **Treasury Protection**: Multi-step validation before fund transfers
- **Delegation Safety**: Prevention of circular delegation and self-delegation

## Smart Contract Functions

### Public Functions

#### Governance
- `create-motion()`: Create new governance proposals
- `cast-ballot()`: Vote on active proposals
- `execute-motion()`: Execute approved proposals
- `assign-delegate()`: Delegate voting power
- `withdraw-delegation()`: Remove delegation

#### Administrative
- `set-dao-administrator()`: Transfer administrative control
- `update-dao-parameters()`: Modify governance settings
- `toggle-motion-submission()`: Enable/disable proposal creation
- `toggle-ballot-casting()`: Enable/disable voting

### Read-Only Functions
- `get-motion-details()`: Retrieve complete proposal information
- `get-participant-info()`: Get voter information and statistics
- `get-delegation-info()`: Check delegation relationships

## Error Codes

- `u100`: Unauthorized access
- `u101`: Proposal already exists
- `u102`: Proposal not found
- `u103`: Already voted on proposal
- `u104`: Proposal voting period ended
- `u105`: Insufficient token balance
- `u110`: Proposal not active
- `u115`: Proposal already executed
- `u116`: Cannot delegate to self
- `u117`: Invalid quorum settings

## Development

### Prerequisites
- Clarinet CLI for local development
- Node.js for testing utilities
- Stacks blockchain testnet access

### Testing
Run the comprehensive test suite:
```bash
clarinet test
```

### Deployment
Deploy to Stacks mainnet:
```bash
clarinet deploy --network mainnet
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request
