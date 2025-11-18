#!/usr/bin/env python3

"""
Advanced Content Overlap Analyzer for ClariFi iOS Documentation
Performs deep content analysis to identify duplicate information and consolidation opportunities
Requirements: 14.1, 14.2, 14.3
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict, Counter
from difflib import SequenceMatcher
import hashlib
import json
from datetime import datetime

class ContentOverlapAnalyzer:
    def __init__(self, root_dir="."):
        self.root_dir = Path(root_dir)
        self.markdown_files = []
        self.content_hashes = {}
        self.similarity_threshold = 0.7
        self.overlap_results = {}
        
    def find_markdown_files(self):
        """Find all markdown files in the project"""
        self.markdown_files = list(self.root_dir.rglob("*.md"))
        # Exclude git directory
        self.markdown_files = [f for f in self.markdown_files if ".git" not in str(f)]
        print(f"Found {len(self.markdown_files)} markdown files")
        
    def extract_content_sections(self, file_path):
        """Extract content sections from markdown file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            try:
                with open(file_path, 'r', encoding='latin-1') as f:
                    content = f.read()
            except:
                print(f"Warning: Could not read {file_path}")
                return {}
        
        sections = {}
        
        # Extract headers and their content
        lines = content.split('\n')
        current_header = "introduction"
        current_content = []
        
        for line in lines:
            if line.startswith('#'):
                # Save previous section
                if current_content:
                    sections[current_header] = '\n'.join(current_content).strip()
                
                # Start new section
                current_header = re.sub(r'^#+\s*', '', line).lower().strip()
                current_content = []
            else:
                current_content.append(line)
        
        # Save last section
        if current_content:
            sections[current_header] = '\n'.join(current_content).strip()
            
        return sections
    
    def calculate_content_hash(self, content):
        """Calculate hash for content similarity detection"""
        # Normalize content for comparison
        normalized = re.sub(r'\s+', ' ', content.lower().strip())
        normalized = re.sub(r'[^\w\s]', '', normalized)
        return hashlib.md5(normalized.encode()).hexdigest()
    
    def calculate_similarity(self, text1, text2):
        """Calculate similarity between two text blocks"""
        return SequenceMatcher(None, text1, text2).ratio()
    
    def analyze_content_overlap(self):
        """Analyze content overlap between files"""
        print("Analyzing content overlap...")
        
        file_contents = {}
        section_contents = defaultdict(list)
        
        # Extract content from all files
        for file_path in self.markdown_files:
            sections = self.extract_content_sections(file_path)
            file_contents[str(file_path)] = sections
            
            # Group sections by type
            for section_name, content in sections.items():
                if len(content) > 100:  # Only analyze substantial content
                    section_contents[section_name].append({
                        'file': str(file_path),
                        'content': content,
                        'hash': self.calculate_content_hash(content)
                    })
        
        # Find duplicate content
        duplicates = defaultdict(list)
        similar_content = []
        
        # Check for exact duplicates by hash
        hash_groups = defaultdict(list)
        for file_path, sections in file_contents.items():
            for section_name, content in sections.items():
                if len(content) > 50:
                    content_hash = self.calculate_content_hash(content)
                    hash_groups[content_hash].append({
                        'file': file_path,
                        'section': section_name,
                        'content': content[:200] + "..." if len(content) > 200 else content
                    })
        
        # Report exact duplicates
        for content_hash, items in hash_groups.items():
            if len(items) > 1:
                duplicates[content_hash] = items
        
        # Check for similar content
        all_sections = []
        for file_path, sections in file_contents.items():
            for section_name, content in sections.items():
                if len(content) > 100:
                    all_sections.append({
                        'file': file_path,
                        'section': section_name,
                        'content': content
                    })
        
        # Compare all sections for similarity
        for i, section1 in enumerate(all_sections):
            for j, section2 in enumerate(all_sections[i+1:], i+1):
                similarity = self.calculate_similarity(section1['content'], section2['content'])
                if similarity > self.similarity_threshold:
                    similar_content.append({
                        'similarity': similarity,
                        'file1': section1['file'],
                        'section1': section1['section'],
                        'file2': section2['file'],
                        'section2': section2['section'],
                        'content_preview': section1['content'][:150] + "..."
                    })
        
        self.overlap_results = {
            'exact_duplicates': dict(duplicates),
            'similar_content': similar_content,
            'total_files_analyzed': len(self.markdown_files),
            'sections_analyzed': sum(len(sections) for sections in file_contents.values())
        }
        
        return self.overlap_results
    
    def categorize_by_content_type(self):
        """Categorize files by their content type and purpose"""
        print("Categorizing files by content type...")
        
        categories = {
            'requirements': [],
            'design': [],
            'implementation': [],
            'completion': [],
            'testing': [],
            'reference': [],
            'guides': [],
            'archive': [],
            'temporary': [],
            'other': []
        }
        
        # Keywords for categorization
        category_keywords = {
            'requirements': ['requirement', 'user story', 'acceptance criteria', 'shall', 'must'],
            'design': ['architecture', 'design', 'component', 'interface', 'pattern'],
            'implementation': ['implementation', 'code', 'function', 'class', 'method'],
            'completion': ['complete', 'summary', 'finished', 'done', 'task completion'],
            'testing': ['test', 'testing', 'unit test', 'integration test', 'coverage'],
            'reference': ['reference', 'api', 'documentation', 'guide', 'manual'],
            'guides': ['how to', 'tutorial', 'guide', 'walkthrough', 'instructions'],
            'temporary': ['temp', 'temporary', 'draft', 'wip', 'work in progress']
        }
        
        for file_path in self.markdown_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read().lower()
            except:
                continue
            
            file_str = str(file_path)
            filename = file_path.name.lower()
            
            # Check if in archive directory
            if 'archive' in file_str:
                categories['archive'].append(file_str)
                continue
            
            # Score each category
            scores = {}
            for category, keywords in category_keywords.items():
                score = sum(content.count(keyword) for keyword in keywords)
                # Boost score for filename matches
                score += sum(2 for keyword in keywords if keyword in filename)
                scores[category] = score
            
            # Assign to highest scoring category
            if max(scores.values()) > 0:
                best_category = max(scores, key=scores.get)
                categories[best_category].append(file_str)
            else:
                categories['other'].append(file_str)
        
        return categories
    
    def identify_consolidation_opportunities(self):
        """Identify specific consolidation opportunities"""
        print("Identifying consolidation opportunities...")
        
        opportunities = {
            'merge_candidates': [],
            'archive_candidates': [],
            'delete_candidates': [],
            'reference_consolidation': []
        }
        
        # Files with similar names that could be merged
        file_groups = defaultdict(list)
        for file_path in self.markdown_files:
            # Group by base name (removing common suffixes)
            base_name = file_path.stem
            base_name = re.sub(r'_(COMPLETE|SUMMARY|IMPLEMENTATION|TASK_\d+)', '', base_name)
            base_name = re.sub(r'_\d+$', '', base_name)
            file_groups[base_name].append(str(file_path))
        
        for base_name, files in file_groups.items():
            if len(files) > 1:
                opportunities['merge_candidates'].append({
                    'base_name': base_name,
                    'files': files,
                    'reason': 'Similar naming pattern suggests related content'
                })
        
        # Files that are completion summaries (archive candidates)
        for file_path in self.markdown_files:
            filename = file_path.name.upper()
            if any(keyword in filename for keyword in ['COMPLETE', 'SUMMARY', 'FINISHED', 'DONE']):
                opportunities['archive_candidates'].append(str(file_path))
        
        # Small files that might be consolidated
        for file_path in self.markdown_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = len(f.readlines())
                if lines < 20:
                    opportunities['delete_candidates'].append({
                        'file': str(file_path),
                        'lines': lines,
                        'reason': 'Very small file, content might be consolidated elsewhere'
                    })
            except:
                continue
        
        return opportunities
    
    def generate_report(self):
        """Generate comprehensive overlap analysis report"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        report = f"""# Advanced Content Overlap Analysis Report

**Generated:** {timestamp}

## Executive Summary

This report provides detailed analysis of content overlap, duplication, and consolidation opportunities across {len(self.markdown_files)} markdown files in the ClariFi iOS codebase.

## Content Overlap Analysis

### Exact Duplicates Found: {len(self.overlap_results.get('exact_duplicates', {}))}

"""
        
        # Report exact duplicates
        for content_hash, items in self.overlap_results.get('exact_duplicates', {}).items():
            if len(items) > 1:
                report += f"#### Duplicate Content Group:\n"
                for item in items:
                    report += f"- **{item['file']}** (section: {item['section']})\n"
                report += f"  - Content preview: {item['content']}\n\n"
        
        # Report similar content
        similar_content = self.overlap_results.get('similar_content', [])
        report += f"### Similar Content Found: {len(similar_content)} pairs\n\n"
        
        # Sort by similarity score
        similar_content.sort(key=lambda x: x['similarity'], reverse=True)
        
        for item in similar_content[:10]:  # Top 10 most similar
            report += f"#### Similarity: {item['similarity']:.2%}\n"
            report += f"- **File 1:** {item['file1']} (section: {item['section1']})\n"
            report += f"- **File 2:** {item['file2']} (section: {item['section2']})\n"
            report += f"- **Preview:** {item['content_preview']}\n\n"
        
        # Add categorization results
        categories = self.categorize_by_content_type()
        report += "## File Categorization\n\n"
        
        for category, files in categories.items():
            if files:
                report += f"### {category.title()}: {len(files)} files\n"
                for file in files[:5]:  # Show first 5
                    report += f"- {file}\n"
                if len(files) > 5:
                    report += f"- ... and {len(files) - 5} more\n"
                report += "\n"
        
        # Add consolidation opportunities
        opportunities = self.identify_consolidation_opportunities()
        report += "## Consolidation Opportunities\n\n"
        
        report += f"### Merge Candidates: {len(opportunities['merge_candidates'])}\n"
        for candidate in opportunities['merge_candidates'][:5]:
            report += f"#### {candidate['base_name']}\n"
            report += f"- **Reason:** {candidate['reason']}\n"
            report += f"- **Files to merge:**\n"
            for file in candidate['files']:
                report += f"  - {file}\n"
            report += "\n"
        
        report += f"### Archive Candidates: {len(opportunities['archive_candidates'])}\n"
        for file in opportunities['archive_candidates'][:10]:
            report += f"- {file}\n"
        
        report += f"\n### Small Files (Potential Deletion): {len(opportunities['delete_candidates'])}\n"
        for candidate in opportunities['delete_candidates'][:10]:
            report += f"- {candidate['file']} ({candidate['lines']} lines) - {candidate['reason']}\n"
        
        report += f"""

## Recommendations

### Immediate Actions:
1. **Archive {len(opportunities['archive_candidates'])} completion/summary files** to docs/archive/
2. **Merge {len(opportunities['merge_candidates'])} file groups** with similar content
3. **Review {len(similar_content)} similar content pairs** for consolidation
4. **Evaluate {len(opportunities['delete_candidates'])} small files** for deletion or merging

### Consolidation Strategy:
1. Start with exact duplicates (highest confidence)
2. Process similar content pairs above 80% similarity
3. Merge files with similar naming patterns
4. Archive historical completion documents
5. Consolidate reference materials into comprehensive guides

---
*Report generated by content_overlap_analyzer.py on {timestamp}*
"""
        
        return report

def main():
    analyzer = ContentOverlapAnalyzer()
    
    print("Starting advanced content overlap analysis...")
    analyzer.find_markdown_files()
    analyzer.analyze_content_overlap()
    
    # Generate and save report
    report = analyzer.generate_report()
    
    with open('advanced_content_overlap_report.md', 'w', encoding='utf-8') as f:
        f.write(report)
    
    # Save detailed results as JSON for further processing
    with open('content_overlap_data.json', 'w', encoding='utf-8') as f:
        json.dump(analyzer.overlap_results, f, indent=2, default=str)
    
    print("✓ Advanced content overlap analysis complete!")
    print("Reports generated:")
    print("  - advanced_content_overlap_report.md")
    print("  - content_overlap_data.json")

if __name__ == "__main__":
    main()