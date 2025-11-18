#!/bin/bash

# Script to fix all hardcoded USD currency formatters
# Replaces them with proper currency preference system

echo "Fixing currency formatters across the codebase..."

# Create backup
echo "Creating backup..."
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p .backups/$timestamp
cp -r Views .backups/$timestamp/

# Function to replace formatters in a file
fix_file() {
    local file=$1
    echo "Processing $file..."
    
    # Replace the formatter pattern with currency preference
    # This is a complex replacement, so we'll do it with perl for better regex
    perl -i -pe 's/let formatter = NumberFormatter\(\)\s+formatter\.numberStyle = \.currency\s+formatter\.currencyCode = "USD"\s+return formatter\.string\(from: amount as NSDecimalNumber\) \?\? "\$0\.00"/return CurrencyPreferenceManager.shared.formatWithSymbol(amount)/gs' "$file"
    
    # Also handle NSNumber variant
    perl -i -pe 's/let formatter = NumberFormatter\(\)\s+formatter\.numberStyle = \.currency\s+formatter\.currencyCode = "USD"\s+return formatter\.string\(from: amount as NSNumber\) \?\? "\$0\.00"/return CurrencyPreferenceManager.shared.formatWithSymbol(Decimal(truncating: amount as NSNumber))/gs' "$file"
}

# Files to fix
files=(
    "Views/HomeView.swift"
    "Views/BudgetView.swift"
    "Views/TransactionRowView.swift"
    "Views/TransactionDetailView.swift"
    "Views/TransactionsListView.swift"
    "Views/BudgetCreationView.swift"
    "Views/RecurringTransactionsListView.swift"
    "Views/ScenarioPlanningView.swift"
    "Views/CashflowForecastView.swift"
    "Views/TransactionReviewView.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        fix_file "$file"
    else
        echo "Warning: $file not found"
    fi
done

echo ""
echo "Done! Backup saved to .backups/$timestamp/"
echo ""
echo "Please verify the changes and test the app."
