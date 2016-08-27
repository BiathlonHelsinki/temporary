
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  api_status = Net::Ping::TCP.new(ENV['biathlon_api_server'],  ENV['biathlon_api_port'], 1).ping?
  if api_status != false
    api = BiathlonApi.new
    balance = api.api_get("/users/#{user.id}/get_balance")
    if balance
      user.latest_balance = balance.to_i
      user.latest_balance_checked_at = Time.now.to_i
      user.save(validate: false)
    end
  end
end