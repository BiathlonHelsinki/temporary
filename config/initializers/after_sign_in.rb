
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  # set latest balance
  api = BiathlonApi.new
  balance = api.api_get("/users/#{user.id}/get_balance")
  if balance
    user.latest_balance = balance.to_i
    user.latest_balance_checked_at = Time.now.to_i
    user.save(validate: false)
  end
  
end