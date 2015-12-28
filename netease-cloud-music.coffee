crypto = require 'crypto'
bigInt = require 'big-integer'
request = require 'superagent'

#登录加密,参考 https://github.com/stkevintan/Cube/blob/master/src/model/Crypto.js
addPadding = (encText, modulus) ->
  ml = modulus.length
  i = 0
  while (ml > 0 and modulus[i] is '0')
    ml--
    i++
  num = ml - encText.length
  prefix = ''
  i = 0
  loop
    break if i >= num
    prefix += '0'
    i++
  prefix + encText

aesEncrypt = (text, secKey) ->
  cipher = crypto.createCipheriv 'AES-128-CBC', secKey, '0102030405060708'
  cipher.update(text, 'utf-8', 'base64') + cipher.final('base64')

rsaEncrypt = (text, exponent, modulus) ->
  rText = ''
  radix = 16
  i = text.length - 1
  loop
    break if i < 0
    rText += text[i]
    i--
  biText = bigInt(new Buffer(rText).toString('hex'), radix)
  biEx = bigInt exponent, radix
  biMod = bigInt modulus, radix
  biRet = biText.modPow biEx, biMod
  addPadding biRet.toString(radix), modulus

createSecretKey = (size) ->
  keys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  key = ""
  i = 0
  loop
    break if i >= size
    pos = Math.random() * keys.length
    pos = Math.floor pos
    key = key + keys.charAt pos
    i++
  key

modulus = '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7'
nonce = '0CoJUm6Qyw8W8jud'
pubKey = '010001'
Crypto =
    MD5: (text) ->
      crypto.createHash('md5').update(text).digest 'hex'
    aesRsaEncrypt: (text) ->
      secKey = createSecretKey(16)
      params: aesEncrypt aesEncrypt(text, nonce), secKey
      encSecKey: rsaEncrypt secKey, pubKey, modulus

header =
  'Accept': '*/*'
  'Accept-Encoding': 'gzip,deflate,sdch'
  'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3'
  'Connection': 'keep-alive'
  'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
  'Host': 'music.163.com'
  'Cookie': 'appver=1.5.0.75771;'
  'Referer': 'http://music.163.com/'
  'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:39.0) Gecko/20100101 Firefox/39.0'

httpRequest = (method, url, data, callback) ->
  ret = request.post(url).send data
  ret.set(header).timeout(10000).end callback

# 自动签到
dailyTask = (userName, password, callback) ->
  body =
    userName: userName
    password: Crypto.MD5 password
  enbody = Crypto.aesRsaEncrypt(JSON.stringify(body))
  dailyTask_url = 'http://music.163.com/weapi/point/dailyTask/?csrf_token='
  httpRequest 'post', dailyTask_url, enbody, (err, res) ->
    if err
      callback
        msg: 'sign in http error ' + err
        type: 1
      return
    data = JSON.parse res.text
    unless data.code is 200
      callback
        msg: "username or password incorrect"
        type: 0
