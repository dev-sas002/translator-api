# Load the Rails application.
require_relative "application"

# Optional local-development convenience: load environment variables from an
# untracked YAML file before the app boots. The file is not required, and an
# environment with no entry in it is simply skipped.
env_file = Rails.root.join("config/environment_variables.yml").to_s
if File.exist?(env_file)
  # `aliases: true` so YAML anchors (`<<: *default`) keep working on Psych 4,
  # which disables them by default.
  loaded = begin
    YAML.load_file(env_file, aliases: true)
  rescue ArgumentError
    YAML.load_file(env_file)
  end
  (loaded.is_a?(Hash) ? loaded[Rails.env] : nil)&.each do |key, value|
    # ENV only accepts String values; a YAML integer such as a port would
    # otherwise raise TypeError and abort boot.
    ENV[key.to_s] = value&.to_s
  end
end

# Initialize the Rails application.
Rails.application.initialize!
