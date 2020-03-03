# porter
反向代理 | 端口转发 | 端口复用

#### 功能
根据数据包的Host内容,将http请求、http代理以及带有http混淆的代理(ss/ssr)转发到指定的地址，可简单实现ss/ssr单端口多用户。

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

#### 使用场景举例
##### ss/ssr单端口多用户
环境：shadowsocks-libev+obfs(http)服务端 or shadowsocksr(http_simple混淆)服务端</br></br>
配置文件参数说明：
```
listen - 程序监听的端口
param - ss/ssr客户端填写的混淆参数(用户标志)
address - ss/ssr服务端的地址和端口(可以本地地址也可以远程地址)
host - 留空(本场景不需要使用该参数)
```
</br>
最后，客户端配置上将地址和端口更改为本程序的地址和端口，混淆参数设置为配置文件中forward.param含有的混淆，即可成功连接目标ss/ssr服务端</br>


