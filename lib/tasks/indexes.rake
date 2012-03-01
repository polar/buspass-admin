namespace :db do
  namespace :mongo do
    desc "Create mongo_mapper indexes"
    task :index => :environment do |t, args|
      #puts ("DATABASE #{args[:database]}")
      CreateIndexes.database()
    end
  end
end