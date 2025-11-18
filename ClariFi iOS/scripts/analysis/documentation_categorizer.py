#!/usr/bin/env python3

"""
Documentation Categorization Tool for ClariFi iOS
Categorizes documentation by type, importance, and consolidation priority
Requirements: 14.1, 14.2, 14.3
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict, Counter
from datetime import datetime

class DocumentationCategorizer:
    def __init__(self, root_dir="."):
        self.root_dir = Path(root_dir)
        self.markdown_files = []
        self.categorization_results = {}
        
        # Define categorization rules
        self.category_rules = {
            'requirements': {
                'keywords': ['requirement', 'user story', 'acceptance criteria', 'shall', 'must', 'epic'],
                'filename_patterns': [r'requirements?\.md$', r'.*_requirements\.md$'],
                'importance': 'essential'
            },
            'design': {
                'keywords': ['architecture', 'design', 'component', 'interface', 'pattern', 'system'],
                'filename_patterns': [r'design\.md$', r'.*_design\.md$', r'architecture\.md$'],
                'importance': 'essential'
            },
            'implementation': {
                'keywords': ['implementation', 'code', 'function', 'class', 'method', 'algorithm'],
                'filename_patterns': [r'.*implementation.*\.md$', r'.*_impl\.md$'],
                'importance': 'reference'
            },
            'completion': {
                'keywords': ['complete', 'completed', 'summary', 'finished', 'done', 'task completion'],
                'filename_patterns': [r'.*complete.*\.md$', r'.*summary.*\.md$', r'.*finished.*\.md$'],
                'importance': 'archive'
            },
            'testing': {
                'keywords': ['test', 'testing', 'unit test', 'integration test', 'coverage', 'qa'],
                'filename_patterns': [r'.*test.*\.md$', r'.*testing.*\.md$'],
                'importance': 'reference'
            },
            'reference': {
                'keywords': ['reference', 'api', 'documentation', 'manual', 'specification'],
                'filename_patterns': [r'.*reference.*\.md$', r'.*api.*\.md$', r'.*spec.*\.md$'],
                'importance': 'reference'
            },
            'guides': {
                'keywords': ['how to', 'tutorial', 'guide', 'walkthrough', 'instructions', 'quickstart'],
                'filename_patterns': [r'.*guide.*\.md$', r'.*tutorial.*\.md$', r'how.*to.*\.md$'],
                'importance': 'essential'
            },
            'troubleshooting': {
                'keywords': ['troubleshooting', 'problem', 'issue', 'error', 'fix', 'solution'],
                'filename_patterns': [r'.*troubleshoot.*\.md$', r'.*fix.*\.md$', r'.*issue.*\.md$'],
                'importance': 'essential'
            },
            'temporary': {
                'keywords': ['temp', 'temporary', 'draft', 'wip', 'work in progress', 'todo'],
                'filename_patterns': [r'.*temp.*\.md$', r'.*draft.*\.md$', r'.*wip.*\.md$'],
                'importance': 'delete'
            },
            'task_tracking': {
                'keywords': ['task', 'todo', 'progress', 'status', 'milestone'],
                'filename_patterns': [r'task.*\.md$', r'.*task.*\.md$', r'todo.*\.md$'],
                'importance': 'archive'
            }
        }
        
        # Importance levels for consolidation priority
        self.importance_levels = {
            'essential': 1,    # Keep and consolidate
            'reference': 2,    # Consolidate into reference docs
            'archive': 3,      # Move to archive
            'delete': 4        # Consider for deletion
        }
    
    def find_markdown_files(self):
        """Find all markdown files in the project"""
        self.markdown_files = list(self.root_dir.rglob("*.md"))
        # Exclude git directory
        self.markdown_files = [f for f in self.markdown_files if ".git" not in str(f)]
        print(f"Found {len(self.markdown_files)} markdown files for categorization")
    
    def analyze_file_content(self, file_path):
        """Analyze file content for categorization"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            try:
                with open(file_path, 'r', encoding='latin-1') as f:
                    content = f.read()
            except:
                return {'content': '', 'word_count': 0, 'line_count': 0}
        
        lines = content.split('\n')
        words = content.split()
        
        return {
            'content': content.lower(),
            'word_count': len(words),
            'line_count': len(lines),
            'has_headers': bool(re.search(r'^#+\s', content, re.MULTILINE)),
            'has_code_blocks': bool(re.search(r'```', content)),
            'has_links': bool(re.search(r'\[.*\]\(.*\)', content)),
            'has_tables': bool(re.search(r'\|.*\|', content))
        }
    
    def categorize_file(self, file_path):
        """Categorize a single file"""
        file_analysis = self.analyze_file_content(file_path)
        filename = file_path.name.lower()
        file_str = str(file_path).lower()
        content = file_analysis['content']
        
        # Score each category
        category_scores = {}
        
        for category, rules in self.category_rules.items():
            score = 0
            
            # Check filename patterns
            for pattern in rules['filename_patterns']:
                if re.search(pattern, filename):
                    score += 10
            
            # Check keywords in content
            for keyword in rules['keywords']:
                score += content.count(keyword)
            
            # Boost score for directory-based hints
            if category in file_str:
                score += 5
            
            category_scores[category] = score
        
        # Determine primary category
        if max(category_scores.values()) > 0:
            primary_category = max(category_scores, key=category_scores.get)
        else:
            primary_category = 'other'
        
        # Determine importance level
        importance = self.category_rules.get(primary_category, {}).get('importance', 'reference')
        
        # Special rules for specific patterns
        if 'archive' in file_str:
            importance = 'archive'
        elif file_analysis['word_count'] < 50:
            importance = 'delete'
        elif 'readme' in filename:
            importance = 'essential'
            primary_category = 'guides'
        
        return {
            'category': primary_category,
            'importance': importance,
            'scores': category_scores,
            'analysis': file_analysis,
            'consolidation_priority': self.importance_levels[importance]
        }
    
    def categorize_all_files(self):
        """Categorize all markdown files"""
        print("Categorizing all documentation files...")
        
        results = {}
        category_counts = defaultdict(int)
        importance_counts = defaultdict(int)
        
        for file_path in self.markdown_files:
            result = self.categorize_file(file_path)
            results[str(file_path)] = result
            
            category_counts[result['category']] += 1
            importance_counts[result['importance']] += 1
        
        self.categorization_results = {
            'files': results,
            'summary': {
                'total_files': len(self.markdown_files),
                'category_counts': dict(category_counts),
                'importance_counts': dict(importance_counts)
            }
        }
        
        return self.categorization_results
    
    def generate_consolidation_plan(self):
        """Generate detailed consolidation plan based on categorization"""
        plan = {
            'essential_files': [],
            'reference_consolidation': [],
            'archive_candidates': [],
            'deletion_candidates': [],
            'merge_groups': defaultdict(list)
        }
        
        for file_path, result in self.categorization_results['files'].items():
            importance = result['importance']
            category = result['category']
            
            if importance == 'essential':
                plan['essential_files'].append({
                    'file': file_path,
                    'category': category,
                    'word_count': result['analysis']['word_count']
                })
            elif importance == 'reference':
                plan['reference_consolidation'].append({
                    'file': file_path,
                    'category': category,
                    'word_count': result['analysis']['word_count']
                })
            elif importance == 'archive':
                plan['archive_candidates'].append({
                    'file': file_path,
                    'category': category,
                    'reason': f"Categorized as {category} with archive importance"
                })
            elif importance == 'delete':
                plan['deletion_candidates'].append({
                    'file': file_path,
                    'category': category,
                    'word_count': result['analysis']['word_count'],
                    'reason': f"Small file ({result['analysis']['word_count']} words) or temporary content"
                })
            
            # Group files by category for potential merging
            plan['merge_groups'][category].append(file_path)
        
        # Remove single-file groups
        plan['merge_groups'] = {k: v for k, v in plan['merge_groups'].items() if len(v) > 1}
        
        return plan
    
    def generate_report(self):
        """Generate comprehensive categorization report"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        summary = self.categorization_results['summary']
        plan = self.generate_consolidation_plan()
        
        report = f"""# Documentation Categorization Report

**Generated:** {timestamp}

## Executive Summary

Analyzed {summary['total_files']} markdown files and categorized them by type and consolidation priority.

## Categorization Results

### Files by Category:
"""
        
        for category, count in summary['category_counts'].items():
            report += f"- **{category.title()}:** {count} files\n"
        
        report += f"""

### Files by Importance Level:
"""
        
        for importance, count in summary['importance_counts'].items():
            report += f"- **{importance.title()}:** {count} files\n"
        
        report += f"""

## Detailed Consolidation Plan

### Essential Files to Keep ({len(plan['essential_files'])} files)
These files should be preserved and potentially consolidated:

"""
        
        for item in sorted(plan['essential_files'], key=lambda x: x['category']):
            report += f"- **{item['file']}** ({item['category']}, {item['word_count']} words)\n"
        
        report += f"""

### Reference Files for Consolidation ({len(plan['reference_consolidation'])} files)
These files should be merged into comprehensive reference documents:

"""
        
        # Group reference files by category
        ref_by_category = defaultdict(list)
        for item in plan['reference_consolidation']:
            ref_by_category[item['category']].append(item)
        
        for category, items in ref_by_category.items():
            report += f"#### {category.title()} Reference Files:\n"
            for item in items:
                report += f"- {item['file']} ({item['word_count']} words)\n"
            report += "\n"
        
        report += f"""### Archive Candidates ({len(plan['archive_candidates'])} files)
These files should be moved to docs/archive/:

"""
        
        for item in plan['archive_candidates'][:20]:  # Show first 20
            report += f"- **{item['file']}** - {item['reason']}\n"
        
        if len(plan['archive_candidates']) > 20:
            report += f"- ... and {len(plan['archive_candidates']) - 20} more files\n"
        
        report += f"""

### Deletion Candidates ({len(plan['deletion_candidates'])} files)
These files are candidates for deletion (small or temporary):

"""
        
        for item in plan['deletion_candidates']:
            report += f"- **{item['file']}** ({item['word_count']} words) - {item['reason']}\n"
        
        report += f"""

### Merge Groups
Files that could be merged by category:

"""
        
        for category, files in plan['merge_groups'].items():
            if len(files) > 1:
                report += f"#### {category.title()} ({len(files)} files):\n"
                for file in files:
                    report += f"- {file}\n"
                report += "\n"
        
        report += f"""

## Recommended Target Structure

Based on the analysis, the following consolidated structure is recommended:

### Core Documentation (5-7 files):
1. **README.md** - Project overview and quick start
2. **ARCHITECTURE.md** - Technical architecture and design patterns  
3. **CONTRIBUTING.md** - Development guidelines and standards
4. **TROUBLESHOOTING.md** - Common issues and solutions
5. **USER_GUIDE.md** - Comprehensive feature usage guide

### Reference Documentation (3-5 files):
1. **docs/reference/API_REFERENCE.md** - Consolidated API documentation
2. **docs/reference/TESTING_GUIDE.md** - Testing procedures and standards
3. **docs/reference/CURRENCY_SUPPORT.md** - Currency feature documentation
4. **docs/reference/STATEMENT_FORMATS.md** - Supported formats reference

### Spec Documentation (per feature):
- **requirements.md** - Feature requirements
- **design.md** - Feature design
- **tasks.md** - Implementation tasks

## Implementation Priority

1. **Phase 1:** Archive {len(plan['archive_candidates'])} completion/summary files
2. **Phase 2:** Delete {len(plan['deletion_candidates'])} small/temporary files  
3. **Phase 3:** Consolidate {len(plan['reference_consolidation'])} reference files
4. **Phase 4:** Merge related files in {len(plan['merge_groups'])} categories
5. **Phase 5:** Create final consolidated structure

**Expected Reduction:** {summary['total_files']} → 12-15 files (~{100 - (15 * 100 // summary['total_files'])}% reduction)

---
*Report generated by documentation_categorizer.py on {timestamp}*
"""
        
        return report

def main():
    categorizer = DocumentationCategorizer()
    
    print("Starting documentation categorization...")
    categorizer.find_markdown_files()
    categorizer.categorize_all_files()
    
    # Generate and save report
    report = categorizer.generate_report()
    
    with open('documentation_categorization_report.md', 'w', encoding='utf-8') as f:
        f.write(report)
    
    # Save detailed results as JSON
    with open('categorization_data.json', 'w', encoding='utf-8') as f:
        json.dump(categorizer.categorization_results, f, indent=2, default=str)
    
    print("✓ Documentation categorization complete!")
    print("Reports generated:")
    print("  - documentation_categorization_report.md")
    print("  - categorization_data.json")

if __name__ == "__main__":
    main()