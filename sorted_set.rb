# We want to create a sorted set on redis and test its speed. See if it can handle
# several requests per second.

# We can put any string as the member ofa redis queue
require 'pry'
require 'redis'

def redis
  ip = ENV['REDIS_SERVER_IP']
  pw = ENV['REDIS_SERVER_PW']

  @redis ||= Redis.new(
    host: ip,
    password: pw
  )
end

# Seed the queue
id = 0
100.times do
  score = 0
  10.times do
    score += 1
    id += 1
    redis.zadd "z", score, id.to_s
  end
end

binding.pry
