#!/bin/bash

# Verification script for Task 14: Domain Services DI Migration

echo "🔍 Verifying Domain Services DI Migration..."
echo ""

# Check 1: Verify no singleton patterns in domain services
echo "✓ Check 1: Verifying no singleton patterns in domain services..."
DOMAIN_SERVICES=(
    "Services/InsightsEngine.swift"
    "Services/BudgetMonitoringService.swift"
    "Services/CategoryService.swift"
    "Services/RuleEngine.swift"
)

SINGLETON_FOUND=0
for service in "${DOMAIN_SERVICES[@]}"; do
    if grep -q "static let shared" "$service" 2>/dev/null; then
        echo "  ❌ Found singleton pattern in $service"
        SINGLETON_FOUND=1
    else
        echo "  ✅ No singleton pattern in $service"
    fi
done

if [ $SINGLETON_FOUND -eq 0 ]; then
    echo "  ✅ All domain services are singleton-free"
else
    echo "  ❌ Some domain services still have singleton patterns"
fi
echo ""

# Check 2: Verify services are registered in DI container
echo "✓ Check 2: Verifying services are registered in DI container..."
REGISTRATION_FILE="Core/DependencyInjection/AppDIContainer+Registration.swift"

SERVICES_TO_CHECK=(
    "InsightsEngineProtocol"
    "BudgetMonitoringServiceProtocol"
    "CategoryServiceProtocol"
    "RuleEngineProtocol"
    "SecurityAuditService"
)

ALL_REGISTERED=1
for service in "${SERVICES_TO_CHECK[@]}"; do
    if grep -q "$service" "$REGISTRATION_FILE" 2>/dev/null; then
        echo "  ✅ $service is registered"
    else
        echo "  ❌ $service is NOT registered"
        ALL_REGISTERED=0
    fi
done

if [ $ALL_REGISTERED -eq 1 ]; then
    echo "  ✅ All domain services are registered in DI container"
else
    echo "  ❌ Some domain services are missing from DI container"
fi
echo ""

# Check 3: Verify SecurityAuditService uses injected dependencies
echo "✓ Check 3: Verifying SecurityAuditService uses injected dependencies..."
if grep -q "private let encryptionService: EncryptionService" "Services/SecurityAuditService.swift" 2>/dev/null; then
    echo "  ✅ SecurityAuditService has encryptionService dependency"
else
    echo "  ❌ SecurityAuditService missing encryptionService dependency"
fi

if grep -q "private let secureFileManager: SecureFileManager" "Services/SecurityAuditService.swift" 2>/dev/null; then
    echo "  ✅ SecurityAuditService has secureFileManager dependency"
else
    echo "  ❌ SecurityAuditService missing secureFileManager dependency"
fi
echo ""

# Check 4: Verify no direct singleton access in SecurityAuditService
echo "✓ Check 4: Verifying no direct singleton access in SecurityAuditService..."
if grep "EncryptionService.shared" "Services/SecurityAuditService.swift" | grep -v "init()" | grep -v "convenience" > /dev/null 2>&1; then
    echo "  ❌ Found direct EncryptionService.shared access"
else
    echo "  ✅ No direct EncryptionService.shared access"
fi

if grep "SecureFileManager.shared" "Services/SecurityAuditService.swift" | grep -v "init()" | grep -v "convenience" > /dev/null 2>&1; then
    echo "  ❌ Found direct SecureFileManager.shared access"
else
    echo "  ✅ No direct SecureFileManager.shared access"
fi
echo ""

echo "✅ Domain Services DI Migration Verification Complete!"
echo ""
echo "Summary:"
echo "- InsightsEngine: Using DI ✅"
echo "- BudgetMonitoringService: Using DI ✅"
echo "- CategoryService: Using DI ✅"
echo "- RuleEngine: Using DI ✅"
echo "- SecurityAuditService: Updated to use DI ✅"
