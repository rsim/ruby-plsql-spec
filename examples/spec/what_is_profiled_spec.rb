require 'what_is_profiled'

describe "what is profiled" do
  it "should run driver" do
    expect {
      plsql.what_is_profiled.driver
    }.not_to raise_error
  end
  
end