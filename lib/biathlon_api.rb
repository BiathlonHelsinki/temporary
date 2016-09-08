require 'httmultiparty'

class BiathlonApi
  API_URL = Figaro.env.biathlon_api_address

  def api_get(url = '/')
    response = HTTParty.get(API_URL + url)
    # TODO more error checking (500 error, etc)
    JSON.parse(response.body)['data']
  end
  
  def api_post(url = '/', options)
    begin
      response = HTTParty.post(API_URL + url, body: options)
      if JSON.parse(response.body)['error']
        JSON.parse(response.body)
      else
        JSON.parse(response.body)
      end
    rescue HTTParty::Error => e
      JSON.parse({error: "Error from #{API_URL + url}: #{e}"}.to_json)
    rescue StandardError => e
      JSON.parse({error: "Error contacting #{API_URL}: #{e}"}.to_json)
    end
  end
  
  
  def api_put(url = '/', options)
    begin
      response = HTTParty.put(API_URL + url, body: options)
      if JSON.parse(response.body)['error']
        JSON.parse(response.body)
      else
        JSON.parse(response.body)['data']
      end
    rescue HTTParty::Error => e
      JSON.parse({error: "Error from #{API_URL + url}: #{e}"}.to_json)
    rescue StandardError => e
      JSON.parse({error: "Error contacting #{API_URL}: #{e}"}.to_json)
    end
  end  
  
  def api_delete(url, options)
    begin
      response = HTTParty.delete(API_URL + url, body: options)
      if JSON.parse(response.body)['error']
        JSON.parse(response.body)
      else
        JSON.parse(response.body)['data']
      end
    rescue HTTParty::Error => e
      JSON.parse({error: "Error from #{API_URL + url}: #{e}"}.to_json)
    rescue StandardError => e
      JSON.parse({error: "Error contacting #{API_URL}: #{e}"}.to_json)
    end
  end
    

  
end