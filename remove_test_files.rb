#!/usr/bin/env ruby

require 'xcodeproj'

# Path to your Xcode project file
project_path = 'ClariFi iOS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# The name of your main application target
main_target_name = 'ClariFi iOS'

# List of test files to remove from the main target's compile sources
test_files_to_remove = [
  'Tests/IntegrationTests.swift',
  'Tests/BiometricAuthServiceTests.swift',
  'Tests/UIIntegrationTests.swift',
  'Tests/EncryptionServiceTests.swift',
  'Tests/SecureFileManagerTests.swift'
]

puts "Opening project: #{project_path}"
puts "Looking for main target: '#{main_target_name}'"

main_target = project.targets.find { |target| target.name == main_target_name }

if main_target
  puts "Found main target: '#{main_target_name}'"
  
  main_target.build_phases.each do |build_phase|
    if build_phase.instance_of?(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
      puts "Processing Sources build phase for '#{main_target_name}'..."
      files_to_delete = []
      
      build_phase.files.each do |build_file|
        file_ref = build_file.file_ref
        if file_ref && test_files_to_remove.include?(file_ref.path)
          puts "  - Marking '#{file_ref.path}' for removal."
          files_to_delete << build_file
        end
      end
      
      files_to_delete.each do |build_file|
        build_phase.remove_build_file(build_file)
        puts "  - Removed '#{build_file.file_ref.path}' from Sources build phase."
      end
      
      if files_to_delete.empty?
        puts "  - No test files found in Sources build phase."
      end
    end
  end
  
  project.save
  puts "Project saved successfully. Test files removed from main target's compile sources."
else
  puts "Error: Main target '#{main_target_name}' not found in the project."
  puts "Available targets:"
  project.targets.each do |target|
    puts "  - #{target.name}"
  end
end

