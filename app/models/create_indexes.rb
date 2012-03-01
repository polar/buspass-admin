class CreateIndexes
  def self.database(database)
    puts "*"*15 + " GENERATING INDEXES FOR #{database} " + "*"*15
    MongoMapper.database = database
    MongoMapper.database.collection_names.each do |coll|
      # Avoid "system.indexes"
      next if coll.index(".")
      model = coll.singularize.camelize.constantize
      puts "Indexing Model #{model}"
      model.create_indexes if model.respond_to?(:create_indexes)
      model.show_indexes if model.respond_to?(:show_indexes)
    end
  end
end