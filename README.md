# porter
反向代理 | 端口转发 | 端口复用

#### 功能
根据数据包的Host内容,将http请求、http代理以及带有http混淆的代理(ss/ssr)转发到指定的地址，可简单实现ss/ssr单端口多用户功能。

#### 参数
```
-config 指定配置文件名(default：config.json)
```

#### json配置文件

```
{
  "listen":":8080",
  "forward":[
    {
      "param":"google.com",
      "address":"127.0.0.1:6077",
      "host":"targeA.host.com"
    },
    {
      "param":"ss.proxy.com",
      "address":"186.168.188.166:6088",
      "host":""
    },
    {
      "param":"ssr.proxy.com",
      "address":"186.168.188.166:6099",
      "host":"targeB.host.com"
    }
  ]
}
```
