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

# Find the main target
target = project.targets.find { |t| t.name == 'ClariFi iOS' }

if target
  # Get the resources build phase
  resources_phase = target.resources_build_phase
  
  # Remove spec files from resources
  files_removed = []
  resources_phase.files.each do |build_file|
    file_ref = build_file.file_ref
    next unless file_ref
    
    file_name = file_ref.path.split('/').last
    if files_to_remove.include?(file_name)
      resources_phase.remove_build_file(build_file)
      files_removed << file_ref.path
      puts "Removed: #{file_ref.path}"
    end
  end
  
  if files_removed.any?
    project.save
    puts "\nSuccessfully removed #{files_removed.count} spec files from Xcode project"
    puts "Files removed:"
    files_removed.each { |f| puts "  - #{f}" }
  else
    puts "No spec files found in resources build phase"
  end
else
  puts "Error: Could not find target 'ClariFi iOS'"
  exit 1
end
