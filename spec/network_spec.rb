require "spec_helper"

describe Network do

  before(:each) do
    @muni = Deployment.new(:name => "Syracuse", :location => [0.0,0.0])
    @muni.save!
    @network = Network.new(:name => "Network One", :deployment => @muni)
    @network.save!
  end

  it "should have empty routes" do
    @network.routes.should == []
  end

  it "should have one route" do
    x = Route.new( :name => "Route 345", :code => "345")
    @network.routes << x
    @network.save!
    @network.routes.length.should == 1
    Route.all.length.should == 1
  end
end