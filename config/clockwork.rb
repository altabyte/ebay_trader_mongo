require 'clockwork'
require_relative '../config/boot'
require_relative '../config/environment'

# http://blog.glaucocustodio.com/2014/02/11/scheduled-backups-with-clockwork-and-backup-gem/
module Clockwork

  configure do |config|
    config[:sleep_timeout] = 10  # Wake every 10 seconds
    config[:tz] = 'UTC'
  end

  class << self
    def execute_rake(file, task)
      require 'rake'
      rake = Rake::Application.new
      Rake.application = rake
      Rake::Task.define_task(:environment)
      load "#{Rails.root}/lib/tasks/#{file}"
      rake[task].invoke
    end
  end

  every(1.hour, 'synchronize eBay listings', at: '**:00') do
    execute_rake 'request.rake', 'request:sync_ebay_listings'
  end

end
