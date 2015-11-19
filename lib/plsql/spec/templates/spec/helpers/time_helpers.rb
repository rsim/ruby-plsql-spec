# return current date with time 00:00:00
def Time.today
  t = Time.now
  Time.local(t.year, t.month, t.day)
end unless Time.respond_to?(:today)
