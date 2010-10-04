# initialize Oracle E-Business Suite session with specified user and responsibility
def init_ebs_user(params={})
  # replace with default user name and responsibility and then it will not be necessary
  # to specify default value as parameter
  params = {
      :user_name => "default user name",
      :responsibility_name => "default responsibility"
     }.merge(params)

  row = plsql.select(:first, "SELECT usr.user_name, res.responsibility_name, usr.user_id,
                       urg.responsibility_id, urg.responsibility_application_id resp_appl_id
                  FROM apps.fnd_user_resp_groups urg,
                       applsys.fnd_user usr,
                       fnd_responsibility_vl res
                 WHERE usr.user_name = :user_name
                   AND res.responsibility_name = :responsibility_name
                   AND urg.user_id = usr.user_id
                   AND res.responsibility_id = urg.responsibility_id",
                   params[:user_name], params[:responsibility_name])

  raise ArgumentError, "Wrong user name or responsibility name" unless row

  plsql.fnd_global.apps_initialize(
        :user_id => row[:user_id], 
        :resp_id => row[:responsibility_id], 
        :resp_appl_id => row[:resp_appl_id]
        )

  # uncomment if logging to dbms_output is necessary
  # plsql.dbms_output.put_line("Initialized " + params[:user_name] + " / " + params[:responsibility_name])

end
