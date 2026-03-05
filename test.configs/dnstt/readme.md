

# for app:

```
socks://#name -> dnstt://?tunnel_per_resolver=4&resolver=8.8.8.8:53&resolver=8.8.4.4:53&domain=dnstt.hiddify.com&publicKey=xxxx
```
or

```
{
  "outbounds": [
    {
      "type": "socks",
      "tag": "socks",
      "version": "5",
      "detour": "dnstt1§hide§"
    },
    {
      "type": "dnstt",
      "tag": "dnstt1§hide§",
      "publicKey": "xxxx",
      "domain": "dnstt.hiddify.com",
      "tunnel_per_resolver": 4,
      "resolvers": ["8.8.8.8:53", "8.8.4.4:53"]
    }
  ]
}
```



# For cli or router or relay server:
download hiddify core from:
https://github.com/hiddify/hiddify-core/releases/

then you can run dnstt in router or relay server via

```
hiddify-core srun -c config.json
```

see: dnstt_raw_config.json
