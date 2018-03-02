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
