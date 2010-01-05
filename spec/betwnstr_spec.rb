require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# load 'betwnstr' procedure into the database
require "betwnstr"

describe "Between string" do
  it "should be correct in normal case" do
    plsql.betwnstr('abcdefg', 2, 5).should == 'bcde'
  end

  it "should be correct with zero start value" do
    plsql.betwnstr('abcdefg', 0, 5).should == 'abcde'
  end

  it "should be correct with way big end value" do
    plsql.betwnstr('abcdefg', 5, 500).should == 'efg'
  end

  it "should be correct with NULL string" do
    plsql.betwnstr(NULL, 5, 500).should == NULL
  end

end

