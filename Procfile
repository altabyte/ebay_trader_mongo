# Environment settings are to be found in .env

web:    bundle exec passenger start -p $PORT --max-pool-size 3
worker: bundle exec sidekiq -c $SIDEKIQ_THREADS
clock:  bundle exec clockwork config/clockwork.rb
