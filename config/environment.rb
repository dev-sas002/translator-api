# Load the Rails application.
require_relative "application"

# Comment the below code if running in docker.
# Uncomment for running on local machine.
env_file = Rails.root.join("config/environment_variables.yml").to_s
if File.exist?(env_file)
  YAML.load_file(env_file)[Rails.env].each do |key, value|
    ENV[key.to_s] = value
  end
end

# Initialize the Rails application.
Rails.application.initialize!
