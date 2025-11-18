# ClariFi iOS

A personal finance management app for iOS that helps users track transactions, manage budgets, and gain insights into their spending patterns.

## Overview

ClariFi is a privacy-focused financial management application that allows users to:
- Upload and parse bank statements using OCR
- Manually enter transactions
- Categorize transactions automatically with rule-based categorization
- Create and monitor budgets with templates
- Generate insights and spending analytics
- Set up recurring transactions
- Plan financial scenarios

## Architecture

ClariFi follows a clean MVVM architecture with dependency injection. For detailed architectural information, see [ARCHITECTURE.md](./ARCHITECTURE.md).

### Key Architectural Patterns

- **Dependency Injection**: Centralized DI container manages all service and repository lifecycles
- **Repository Pattern**: Data access layer with protocol-based design
- **Service Layer**: Business logic separated into domain services
- **MVVM**: Clear separation between Views, ViewModels, and Models
- **Protocol-Oriented**: All major components use protocol boundaries for testability
- **Actor-Based Concurrency**: Thread-safe caching and background processing with Swift actors
- **Async/Await**: Modern concurrency patterns for responsive UI and safe data access

### Project Structure

```
ClariFi iOS/
├── Core/                    # Core infrastructure (DI, Extensions, Error Handling)
├── Models/                  # Core Data models and domain entities
├── Repositories/            # Data access layer
├── Services/                # Business logic and domain services
├── ViewModels/              # Presentation logic
├── Views/                   # SwiftUI views
├── Utilities/               # Helper utilities
├── Tests/                   # Unit and integration tests
└── docs/                    # Documentation
    ├── reference/           # Technical reference docs
    └── archive/             # Historical implementation docs
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Building the Project

1. Clone the repository
2. Open `ClariFi_iOS.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (⌘R)

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suites
./run_security_tests.sh
./run_privacy_tests.sh
./run_premium_tests.sh
./run_categorization_tests.sh
./run_navigation_tests.sh
```

## Key Features

### Statement Processing
- OCR-based statement parsing using Vision framework
- Support for multiple bank statement formats (US and Canadian banks)
- Smart transaction extraction and categorization

### Budget Management
- Template-based budget creation
- Real-time budget monitoring with alerts
- Category-level budget tracking
- Multiple budget periods (weekly, monthly, yearly)

### Transaction Management
- Manual transaction entry
- Batch categorization
- Rule-based auto-categorization
- Recurring transaction support

### Insights & Analytics
- Spending pattern analysis
- Budget performance insights
- Cashflow forecasting
- Scenario planning

### Privacy & Security
- Biometric authentication
- End-to-end encryption for sensitive data
- Privacy dashboard with data controls
- Security audit logging

### Premium Features
- Advanced insights and analytics
- Unlimited budgets
- Scenario planning
- Priority support

## Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Detailed architecture documentation
- **[docs/reference/](./docs/reference/)** - Technical reference documentation
  - State Management Patterns
  - Statement Format Support
  - Test Coverage Analysis
- **[docs/archive/](./docs/archive/)** - Historical implementation documentation

## Development

### Dependency Injection

All dependencies are managed through the centralized DI container:

```swift
// Resolving dependencies in Views
@Environment(\.diContainer) private var container

var body: some View {
    FeatureView(viewModel: container.resolve(FeatureViewModel.self))
}

// ViewModels receive dependencies via constructor
class FeatureViewModel: BaseViewModel {
    init(repository: RepositoryProtocol, service: ServiceProtocol) {
        self.repository = repository
        self.service = service
    }
}
```

### Concurrency Patterns

ClariFi uses Swift's modern concurrency features for thread safety and performance:

**Actor-Based Caching**:
```swift
// FormatterCache is an actor for thread-safe formatter caching
actor FormatterCache {
    func formatterSync(for currency: Currency) -> NumberFormatter {
        // Thread-safe access to cached formatters
    }
}
```

**Background Processing**:
```swift
// Heavy work moved off main actor using Task.detached
@MainActor
class InsightsViewModel: BaseViewModel {
    func loadInsights() async {
        // Fetch data on main actor
        let transactions = try await repository.fetchAll()
        
        // Process on background thread
        let insights = await Task.detached {
            await engine.generateInsights(for: transactions)
        }.value
        
        // Publish results on main actor
        self.insights = insights
    }
}
```

**Async/Sync Formatter Usage**:
```swift
// Synchronous contexts (most common)
let formatted = CurrencyFormatter.shared.format(amount, currency: .usd)

// Async contexts (when already in async function)
let formatted = await CurrencyFormatter.shared.formatAsync(amount, currency: .usd)
```

### Adding New Features

1. Define protocols for any new services or repositories
2. Implement concrete classes
3. Register in `AppDIContainer+Registration.swift`
4. Create ViewModel inheriting from `BaseViewModel`
5. Create SwiftUI View
6. Write unit tests with mock implementations
7. Use actors for thread-safe state management when needed
8. Move heavy computation to background threads with `Task.detached`

### Testing

The project uses a comprehensive testing strategy:
- **Unit Tests**: Test individual components with mocks
- **Integration Tests**: Test workflows across multiple components
- **UI Tests**: Test user interactions and flows

Mock implementations are available for all protocols in `Tests/Mocks/`.

## Contributing

When contributing to this project:

1. Follow the established architectural patterns
2. Use the DI container for all dependencies
3. Write tests for new functionality
4. Update documentation as needed
5. Follow Swift style guidelines
6. Ensure all tests pass before submitting

## License

[Add your license information here]

## Contact

[Add contact information here]
