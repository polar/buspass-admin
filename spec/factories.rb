require 'factory_girl'

Factory.define :admin do |u|
    u.name 'Test User'
    u.email 'user@test.com'
    u.password 'please'
end
Factory.define :muni_admin do |u|
    u.name 'Test User'
    u.email 'user1@test.com'
    u.password 'please'
end

