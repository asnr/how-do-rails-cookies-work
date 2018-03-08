# How do Rails cookies work?

``` shell
$ curl -i localhost:3000/set-cookies
HTTP/1.1 200 OK
...
Set-Cookie: plain=Some+unencrypted+value; path=/
Set-Cookie: signed=IlNvbWUgc2lnbmVkIHZhbHVlIg%3D%3D--72a38c61423c44e799f73dc9bdc1c278a542fc52; path=/
Set-Cookie: encrypted=c01nc2o5ZjU4anZRcUp4SDVUMWZqMUJSK3lxSVJLVDRVNVZ6eDVMc1Mvaz0tLUFUQ1ZDS25qRmFaRnltbDBFUENQbmc9PQ%3D%3D--4e7d056017b1ca66ed3667988a9726b89bec50d9; path=/
...

Consider your cookies set.
```


``` ruby
> Base64.decode64('IlNvbWUgc2lnbmVkIHZhbHVlIg==')
# => "\"Some signed value\""
```

How does the signing work?

The rack request variable `signed_cookie_salt` is defined in action_dispatch/railtie.rb as `config.action_dispatch.signed_cookie_salt`. It is passed into rack in the `env_config` method in application.rb.

`key_generator` is a globally-available method, defined in application.rb, that just returns a an instance of `ActiveSupport::KeyGenerator`. This class is defined in active_support/key_generator.rb. The `key_generator` is initialiased using `secrets.secret_key_base` (inside the class that value is stored in the field `@secret`). Its purpose is to turn the single base secret into several different secrets that can be used for different purposes like signing cookies or encrypting cookies.

`cookies.signed` does its thing with this code:

``` ruby
# active_support/message_verifier.rb

def generate(value)
  data = encode(@serializer.dump(value))
  "#{data}--#{generate_digest(data)}"
end

# ...

def generate_digest(data)
  require "openssl" unless defined?(OpenSSL)
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
end
```

Here, `@secret` is generated by the `key_generator` and `@digest` is a config value passed around via rack like `signed_cookie_salt`. It doesn't need to be set though, because it defaults to `'SHA1'`.


How does cookies.encryption work?

``` ruby
# active_support/message_encryptor.rb

# Encrypt and sign a message. We need to sign the message in order to avoid
# padding attacks. Reference: http://www.limited-entropy.com/padding-oracle-attacks.
def encrypt_and_sign(value)
  verifier.generate(_encrypt(value))
end

# ...

def _encrypt(value)
  cipher = new_cipher
  cipher.encrypt
  cipher.key = @secret

  # Rely on OpenSSL for the initialization vector
  iv = cipher.random_iv
  cipher.auth_data = "" if aead_mode?

  encrypted_data = cipher.update(@serializer.dump(value))
  encrypted_data << cipher.final

  blob = "#{::Base64.strict_encode64 encrypted_data}--#{::Base64.strict_encode64 iv}"
  blob << "--#{::Base64.strict_encode64 cipher.auth_tag}" if aead_mode?
  blob
end

# ...

def new_cipher
  OpenSSL::Cipher.new(@cipher)
end
```

Here
- `@serializer` is set to `ActiveSupport::MessageEncryptor::NullSerializer`; when encrypting cookies, `value` is already serialised.
- `@verifier` is set to `MessageVerifier`, which is the same class used to implement `cookies.signed` (unless `aead_mode?`).

## If we have the secret base key, can we forge signed cookies and decrypt encypted cookies?

Can forge signed cookies: see 'attack_signed_cookies.rb'.
Can decrypt encrypted cookies: see 'attack_encrypted_cookies.rb'.

## What are the default attributes of the cookie header? (Secure, HTTPOnly? Expiry?)

By default, the only directive that is set is `path=/`, which doesn't do a whole lot. (This documented in http://api.rubyonrails.org/classes/ActionDispatch/Cookies.html.)

You have to set other directives manually:

``` ruby
cookies.encrypted[:foo] = {
                            value: 'bar',
                            expires: 1.year.from.now,
                            secure: true,
                            httponly: true,
                          }
```

There has been some talk of making `httponly` the default for new apps, but the discussion fizzled out, see the [Github issue](https://github.com/rails/rails/issues/1449) and the [Google group](https://groups.google.com/forum/#!topic/rubyonrails-core/yDzoifkfqvc).

If you don't manually set the expiry the cookie will be wiped when the browser is closed, unless the user has set the browser to remember tabs when it is opened again ("Show your windows and tabs from last time" on Firefox and "Continue where I left off" on Chrome), in which case they will be persisted to disk after the browser is closed.

## Same question as above, but for when the ActiveRecord session store is being used.

By default, when using `CookieStore` session storage, both the `path=/` and `httponly` directives are set.
