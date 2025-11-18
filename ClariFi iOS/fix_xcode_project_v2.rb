#!/usr/bin/env ruby

# Script to remove spec files from Xcode project
require 'xcodeproj'

project_path = '../ClariFi iOS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to remove (spec files that shouldn't be in the app bundle)
files_to_remove = [
  'design.md',
  'requirements.md', 
  'tasks.md'
]

puts "Searching for spec files in project..."

# Find all file references
files_removed = []
project.files.each do |file_ref|
  file_name = file_ref.path.split('/').last
  
  if files_to_remove.include?(file_name) && file_ref.path.include?('.kiro/specs')
    puts "Found: #{file_ref.path}"
    
    # Remove from all build phases
    project.targets.each do |target|
      target.build_phases.each do |phase|
        if phase.respond_to?(:files)
          phase.files.each do |build_file|
            if build_file.file_ref == file_ref
              phase.remove_build_file(build_file)
              puts "  Removed from #{target.name} - #{phase.class}"
            end
          end
        end
      end
    end
    
    # Remove the file reference itself
    file_ref.remove_from_project
    files_removed << file_ref.path
  end
end

if files_removed.any?
  project.save
  puts "\n✅ Successfully removed #{files_removed.count} spec files from Xcode project"
  puts "\nFiles removed:"
  files_removed.each { |f| puts "  - #{f}" }
else
  puts "\n⚠️  No spec files found in project"
end
