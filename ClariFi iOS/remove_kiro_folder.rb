#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('../ClariFi iOS.xcodeproj')

puts "Searching for .kiro folder references..."

# Find all groups and file references
def find_kiro_refs(group, path = "")
  results = []
  group.children.each do |child|
    current_path = path.empty? ? child.path.to_s : "#{path}/#{child.path}"
    
    if child.path.to_s == ".kiro" || child.path.to_s.include?(".kiro")
      results << {item: child, path: current_path}
      puts "Found: #{current_path} (#{child.class})"
    end
    
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      results += find_kiro_refs(child, current_path)
    end
  end
  results
end

kiro_refs = find_kiro_refs(project.main_group)

if kiro_refs.any?
  puts "\nRemoving .kiro references..."
  kiro_refs.each do |ref|
    # Remove from build phases first
    project.targets.each do |target|
      target.build_phases.each do |phase|
        if phase.respond_to?(:files)
          phase.files.to_a.each do |build_file|
            if build_file.file_ref == ref[:item]
              phase.remove_build_file(build_file)
              puts "  Removed from #{target.name} build phase"
            end
          end
        end
      end
    end
    
    # Remove the reference
    ref[:item].remove_from_project
    puts "  Removed: #{ref[:path]}"
  end
  
  project.save
  puts "\n✅ Successfully removed .kiro folder references"
else
  puts "No .kiro references found"
end
