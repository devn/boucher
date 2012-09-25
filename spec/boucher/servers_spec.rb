require_relative "../spec_helper"
require 'boucher/servers'
require 'ostruct'

describe "Boucher::Servers" do

  let(:remote_servers) {
    [OpenStruct.new(:id => "s1", :tags => {"Env" => "test", "Class" => "foo"}, :state => "stopped"),
     OpenStruct.new(:id => "s2", :tags => {"Env" => "test", "Class" => "bar"}, :state => "pending"),
     OpenStruct.new(:id => "s3", :tags => {"Env" => "dev",  "Class" => "foo"}, :state => "terminated"),
     OpenStruct.new(:id => "s4", :tags => {"Env" => "dev",  "Class" => "bar"}, :state => "running")]
  }

  before do
    @env = Boucher::Config[:env]
    Boucher.compute.stub(:servers).and_return(remote_servers)
  end

  after do
    Boucher::Config[:env] = @env
  end

  it "finds all servers" do
    Boucher::Servers.all.size.should == 4
    Boucher::Servers.all.should == remote_servers
  end

  it "finds classed servers" do
    Boucher::Servers.of_class("blah").should == []
    Boucher::Servers.of_class(:foo).map(&:id).should == ["s1", "s3"]
    Boucher::Servers.of_class("bar").map(&:id).should == ["s2", "s4"]
  end

  it "finds with env servers" do
    Boucher::Servers.in_env("blah").should == []
    Boucher::Servers.in_env("test").map(&:id).should == ["s1", "s2"]
    Boucher::Servers.in_env("dev").map(&:id).should == ["s3", "s4"]
  end

  it "finds servers in a given state" do
    Boucher::Servers.in_state("running").map(&:id).should == ["s4"]
    Boucher::Servers.in_state("terminated").map(&:id).should == ["s3"]
    Boucher::Servers.in_state("pending").map(&:id).should == ["s2"]
    Boucher::Servers.in_state("stopped").map(&:id).should == ["s1"]
  end

  it "finds the first matching server" do
    Boucher::Servers.find.id.should == "s1"
    Boucher::Servers.find(:class => "foo").id.should == "s1"
    Boucher::Servers.find(:class => "bar").id.should == "s2"
    Boucher::Servers.find(:env => "test").id.should == "s1"
    Boucher::Servers.find(:env => "dev").id.should == "s3"
    Boucher::Servers.find(:class => "foo", :env => "test").id.should == "s1"
    Boucher::Servers.find(:class => "foo", :env => "dev").id.should == "s3"
    Boucher::Servers.find(:class => "bar", :env => "test").id.should == "s2"
    Boucher::Servers.find(:class => "bar", :env => "dev").id.should == "s4"
    expect { Boucher::Servers.find(:class => "blah", :env => "dev") }.to raise_error
    expect { Boucher::Servers.find(:class => "foo", :env => "blah") }.to raise_error
  end

  it "raises an error if find returns no results" do
    expect { Boucher::Servers.find(:class => "blah") }.to raise_error(Boucher::Servers::NotFound)
  end

  it "gets a server based on current env when all the servers are running" do
    Boucher::Config[:env] = "test"
    expect { Boucher::Servers["foo"] }.to raise_error
    expect { Boucher::Servers["bar"] }.to raise_error

    Boucher::Config[:env] = "dev"
    expect { Boucher::Servers["foo"] }.to raise_error
    Boucher::Servers["bar"].id.should == "s4"
  end

  it "stops a server" do
    Boucher.should_receive(:change_server_state).with("the id", :stop, "stopped")
    Boucher::Servers.stop("the id")
  end
end