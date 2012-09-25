require_relative "../spec_helper"
require 'boucher/classes'
require 'ostruct'

describe "Boucher Server Classes" do

  before do
    Boucher.stub(:current_user).and_return("joe")
    @server = OpenStruct.new
  end

  it "pull classification from json" do
    json = "{\"boucher\": {\"foo\": 1,\n \"bar\": 2}}"
    Boucher.json_to_class(json).should == {:foo => 1, :bar => 2}
  end

  it "can classify base server" do
    some_class = {:class_name => "base",
                  :meals => ["base"]}
    Boucher.classify(@server, some_class)

    @server.image_id.should == Boucher::Config[:base_image_id]
    @server.flavor_id.should == 'm1.small'
    @server.groups.should == ["SSH"]
    @server.key_name.should == "test_key"
    @server.tags["Class"].should == "base"
    @server.tags["Name"].should_not == nil
    @server.tags["Creator"].should == "joe"
    @server.tags["Env"].should == Boucher::Config[:env]
  end

end
