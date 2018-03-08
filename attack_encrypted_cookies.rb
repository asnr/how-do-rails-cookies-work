# If we have the secret base key, can we decrypt encrypted cookies?

require 'net/http'
require 'base64'
require 'openssl'
require 'cgi'
require 'active_support/all'

LEAKED_BASE_SECRET = 'cdc8441f641f565e967a0786bd31c50be6e7ea790e17c26ab7083bcb00d9a301c86dcd89c9d8585471a6c28322238682b6f2b4dc79cd4aab8a2627961faed43a'.freeze
# The two cookie salts can be configured
DEFAULT_ENCRYPTED_COOKIE_SALT = 'encrypted cookie'.freeze
DEFAULT_ENCRYPTED_SIGNED_COOKIE_SALT = 'signed encrypted cookie'.freeze
# This value can't be configured, it's hardcoded in the Rails source
RAILS_HARDCODED_KEY_GENERATOR_ITERATIONS = 1000

def encrypted_cookie(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)

  cookie_fields = response.get_fields('set-cookie')
  signed_cookie = cookie_fields.find do |cookie_field|
    cookie_key = cookie_field.split('=')[0]
    cookie_key == 'encrypted'
  end

  value_start_index = signed_cookie.index('=') + 1
  value_end_index = signed_cookie.index(';') - 1
  encoded_value = signed_cookie[value_start_index..value_end_index]
  CGI.unescape(encoded_value)
end

key_generator = ActiveSupport::KeyGenerator.new(
  LEAKED_BASE_SECRET,
  iterations: RAILS_HARDCODED_KEY_GENERATOR_ITERATIONS
)
encryption_secret = key_generator.generate_key(DEFAULT_ENCRYPTED_COOKIE_SALT)[0, ActiveSupport::MessageEncryptor.key_len]
sign_secret = key_generator.generate_key(DEFAULT_ENCRYPTED_SIGNED_COOKIE_SALT)

encryptor = ActiveSupport::MessageEncryptor.new(
  encryption_secret,
  sign_secret,
  digest: 'SHA1',
  serializer: ActiveSupport::MessageEncryptor::NullSerializer
)

cookie = encrypted_cookie('http://localhost:3000/set-cookies')
p encryptor.decrypt_and_verify(cookie)
