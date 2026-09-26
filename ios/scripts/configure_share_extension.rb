#!/usr/bin/env ruby
# Idempotently wires the checked-in ShareExtension sources into Runner.xcodeproj.
# Keeping this as code makes the native target reproducible on CI and on any
# future Mac/Xcode environment instead of relying on hand-edited project IDs.

require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |target| target.name == 'Runner' }
raise 'Runner target not found' unless runner

extension = project.targets.find { |target| target.name == 'ShareExtension' }
extension ||= project.new_target(:app_extension, 'ShareExtension', :ios, '14.0')

main_group = project.main_group
share_group = main_group.find_subpath('ShareExtension', true)
share_group.set_source_tree('<group>')
share_group.set_path('ShareExtension')

swift = share_group.files.find { |f| f.path == 'ShareViewController.swift' } || share_group.new_file('ShareViewController.swift')
plist = share_group.files.find { |f| f.path == 'Info.plist' } || share_group.new_file('Info.plist')
entitlements = share_group.files.find { |f| f.path == 'ShareExtension.entitlements' } || share_group.new_file('ShareExtension.entitlements')

base_group = share_group.groups.find { |g| g.path == 'Base.lproj' } || share_group.new_group('Base', 'Base.lproj')
storyboard = base_group.files.find { |f| f.path == 'MainInterface.storyboard' } || base_group.new_file('MainInterface.storyboard')

unless extension.source_build_phase.files_references.include?(swift)
  extension.source_build_phase.add_file_reference(swift)
end
unless extension.resources_build_phase.files_references.include?(storyboard)
  extension.resources_build_phase.add_file_reference(storyboard)
end

extension.build_configurations.each do |config|
  settings = config.build_settings
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'ShareExtension/ShareExtension.entitlements'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'ShareExtension/Info.plist'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
  settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.naylahknee.nanynany.ShareExtension'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SKIP_INSTALL'] = 'YES'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Runner must build and embed the extension.
unless runner.dependencies.any? { |dependency| dependency.target == extension }
  runner.add_dependency(extension)
end

embed_phase = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end
unless embed_phase.files_references.include?(extension.product_reference)
  build_file = embed_phase.add_file_reference(extension.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts 'ShareExtension target configured.'
