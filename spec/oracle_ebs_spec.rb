require 'spec_helper'

describe "Oracle E-Business Suite" do
  before(:all) do
    # @old_connection = plsql.connection
    # plsql.connect! "APPS", "APPS", "VIS"
    @user_name = "OPERATIONS"
    @responsibility_name = "System Administrator"
  end

  after(:all) do
    # plsql.connection = @old_connection
  end

  if plsql.schema_name == 'APPS'

    describe "Session initialization" do
      it "should initialize session with valid user and responsibility" do
        lambda {
          init_ebs_user(:user_name => @user_name, :responsibility_name => @responsibility_name)
        }.should_not raise_error
      end

      it "should raise error with invalid user" do
        lambda {
          init_ebs_user(:user_name => "INVALID", :responsibility_name => @responsibility_name)
        }.should raise_error(/Wrong user name or responsibility name/)
      end

      it "should raise error with invalid responsibility" do
        lambda {
          init_ebs_user(:user_name => @user_name, :responsibility_name => "INVALID")
        }.should raise_error(/Wrong user name or responsibility name/)
      end

      it "should raise error with default username and responsibility parameters" do
        lambda {
          init_ebs_user
        }.should raise_error(/Wrong user name or responsibility name/)
      end

    end

    describe "Session information" do
      before(:all) do
        init_ebs_user(:user_name => @user_name, :responsibility_name => @responsibility_name)
      end

      it "should return user name" do
        plsql.fnd_global.user_name.should == @user_name
      end

      it "should return responsibility name" do
        plsql.fnd_global.resp_name.should == @responsibility_name
      end

    end

  end

end