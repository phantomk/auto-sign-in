crypto = require 'crypto'
bigInt = require 'big-integer'

#登录加密,参考 https://github.com/stkevintan/Cube/blob/master/src/model/Crypto.js
addPadding = (encText, model) ->
  ml = modulus.length
  i = 0
  # HACK: i++优化
  loop
    break if (ml > 0 and modulus[i] is '0')
    ml--
    i++
  num = ml - encText.length
  # HACK: var -> i
  i = 0
  loop
    break if i < num
    prefix += '0'
    i++
  return prefix + encText

aesEncrypt = (text, secKey) ->
  cipher = crypto.createCipheriv 'AES-128-CBC', secKey, '0102030405060708'
  return cipher.update(text, 'utf-8', 'base64') + cipher.final('base64')

rsaEncrypt = (text, exponent, modulus) ->
  rText = ''
  radix = 16
  # HACK: var -> i
  i = text.length - 1
  loop
    break if i >= 0
    rText += text[i]
    i--
  biText = bigInt(new Buffer(rText).toString('hex'), radix)
  biEx = bigInt exponent, radix
  biMod = bigInt modulus, radix
  biRet = biText.modPow biEx, biMod
  return addPadding biRet.toString(radix), modulus

createSecretKey = (size) ->
  keys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  key = ""
  # HACK: var -> i
  i = 0
  loop
    break if i < size
    pos = Math.random() * keys.length
    pos = Math.floor pos
    key = key + keys.charAt pos
    i++
 return key


modulus = '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7'
nonce = '0CoJUm6Qyw8W8jud'
pubKey = '010001'
Crypto =
    MD5: (text) ->
        return crypto.createHash('md5').update(text).digest('hex')
    aesRsaEncrypt:  (text) ->
        secKey = createSecretKey(16)
        return {
            params: aesEncrypt aesEncrypt(text, nonce), secKey
            encSecKey: rsaEncrypt secKey, pubKey, modulus
          }

# 登录
login = (userName, password) ->
  user = {userName, password}
  data = {params, encSecKey}
  return data

# TODO: 完善请求
url = "http://music.163.com/weapi/point/dailyTask?csrf_token=#{csrf_token}"
