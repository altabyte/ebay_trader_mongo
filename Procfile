# Environment settings, such as $PORT, are defined in .env
#
# Sometimes Passenger does not shut down properly.
# Run the following command to stop Passenger.
#
#    ./bin/bundle exec passenger stop --port $PORT
#

web:    bundle exec passenger start -p $PORT --max-pool-size 5
worker: bundle exec sidekiq -c $SIDEKIQ_THREADS
clock:  bundle exec clockwork config/clockwork.rb
