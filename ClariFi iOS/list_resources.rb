#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('../ClariFi iOS.xcodeproj')

target = project.targets.find { |t| t.name == 'ClariFi iOS' }
if target
  puts "Resources in 'ClariFi iOS' target:"
  target.resources_build_phase.files.each do |build_file|
    if build_file.file_ref
      path = build_file.file_ref.real_path.to_s rescue build_file.file_ref.path
      puts "  - #{path}"
    end
  end
end
