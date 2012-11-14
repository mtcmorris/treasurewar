# Installed by guard-jasmine-node

# JavaScript/CoffeeScript watchers

guard 'jasmine-node', :jasmine_node_bin => File.expand_path(File.dirname(__FILE__) + "/node_modules/jasmine-node/bin/jasmine-node") do
  watch(%r{^spec/(.+)_spec\.(js\.coffee|js|coffee)})
  watch(%r{^lib/(.+)\.(js\.coffee|js)|coffee})
end

# JavaScript only watchers
#
# guard "jasmine-node", :jasmine_node_bin => File.expand_path(File.dirname(__FILE__) + "/node_modules/jasmine-node/bin/jasmine-node")  do
#   watch(%r{^spec/.+_spec\.js$})
#   watch(%r{^lib/(.+)\.js$})     { |m| "spec/lib/#{m[1]}_spec.js" }
#   watch('spec/spec_helper.js')
# end
