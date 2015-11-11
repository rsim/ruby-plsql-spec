# load 'betwnstr' procedure into the database
require "betwnstr"

describe "Between string" do
  it "should be correct in normal case" do
    expect(plsql.betwnstr('abcdefg', 2, 5)).to eq 'bcde'
  end

  it "should be correct with zero start value" do
    expect(plsql.betwnstr('abcdefg', 0, 5)).to eq 'abcde'
  end

  it "should be correct with way big end value" do
    expect(plsql.betwnstr('abcdefg', 5, 500)).to eq 'efg'
  end

  it "should be correct with NULL string" do
    expect(plsql.betwnstr(NULL, 5, 500)).to eq NULL
  end

end

