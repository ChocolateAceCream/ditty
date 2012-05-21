require 'spec_helper'
describe HelpersApplication do
  before(:all) do
    @app = TestHelpersApplication.new
  end
  let(:app) { @app }
  describe :protected! do
    it "should be nil if :authorized?" do
      app.stub(:authorized?).and_return true
      app.protected!.should be_nil
    end
    it "should throw :halt if not :authorized?" do
      app.stub(:authorized?).and_return false
      expect { app.protected! }.should throw_symbol :halt
    end
  end

  describe :authorized? do
    it "should return false if username or password is missing" do
      app.authorized?.should be_false
    end
    it "should return false if username or password is wrong" do
      pending "need to research how to test this"
    end
    it "should return true if username or password is correct" do
      pending "need to research how to test this"
    end
  end

  describe :configure! do
    it "should load a file as a hash" do
      app.configure!(ENV['RACK_ENV']).should be_a Hash
    end
    it "should load ENV if it's found" do
      app.configure!(ENV['RACK_ENV'])["title"].should eq "My TEST Ditty's!" 
    end
  end

  describe :database! do
    it "should load the database connection" do
      app.database!(app.configure!(ENV['RACK_ENV'])['database']).should be
    end
  end

  describe :app_title do
    it "should return 'Ditty!' it doesn't know what to do" do
      app.app_title(nil).should eq "Ditty!"
    end
    it "should return ENV title" do
      app.app_title(app.configure!(ENV['RACK_ENV'])).should eq "My TEST Ditty's!" 
    end
  end

  describe :username do
    it "should return auth username" do
      app.username.should eq "test"
    end
  end

  describe :password do
    it "should return auth password" do
      app.password.should eq "test"
    end
  end
end
