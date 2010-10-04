require 'spec_helper'

require 'what_is_profiled'

describe "what is profiled" do
  it "should run driver" do
    lambda {
      plsql.what_is_profiled.driver
    }.should_not raise_error
  end
  
end