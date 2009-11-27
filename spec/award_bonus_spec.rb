require File.dirname(__FILE__) + '/spec_helper'

# load 'award_bonus' procedure into the database
require 'award_bonus'

describe "Award bonus" do
  include EmployeeFactory

  [ [1000,  1234.55,  0.10,   1123.46],
    [nil,   1234.56,  0.10,   123.46],
    [1000,  1234.54,  0.10,   1123.45]
  ].each do |salary, sales_amt, commission_pct, result|
    it "should calculate base salary #{salary.inspect} + sales amount #{sales_amt} * commission percentage #{commission_pct} = salary #{result.inspect}" do
      employee = create_employee(
        :commission_pct => commission_pct,
        :salary => salary
      )
      plsql.award_bonus(employee[:employee_id], sales_amt)
      get_employee(employee[:employee_id])[:salary].should == result
    end
  end

  it "should raise ORA-06510 exception if commission percentage is missing" do
    salary, sales_amt, commission_pct = 1000,  1234.55,  nil
    employee = create_employee(
      :commission_pct => commission_pct,
      :salary => salary
    )
    lambda do
      plsql.award_bonus(employee[:employee_id], sales_amt)
    end.should raise_error(Exception, /ORA-06510/)
  end

end

