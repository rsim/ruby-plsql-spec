module EmployeeFactory
  # Creates new employee with valid field values.
  # Pass in parameters only field values that you want to override.
  def create_employee(params)
    employee = {
      :employee_id => plsql.employees2_seq.nextval,
      :last_name => 'Last',
      :email => 'last@example.com',
      :hire_date => Date.today,
      :job_id => plsql.jobs.first[:job_id],
      :commission_pct => nil,
      :salary => nil
    }.merge(params)
    plsql.employees2.insert employee
    get_employee employee[:employee_id]
  end

  # Select employee by primary key
  def get_employee(employee_id)
    plsql.employees2.first :employee_id => employee_id
  end

end
