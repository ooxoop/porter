# porter
反向代理 | 端口转发 | 端口复用

#### 功能
根据数据包的Host内容,将http请求、http代理以及带有http混淆的代理(ss/ssr)转发到指定的地址，可简单实现ss/ssr单端口多用户。

#### 运行参数
```
-config 指定配置文件名(default：config.json);也可以指定远程地址(example: http://rss.example.com/config),当指定远程地址的时候，每分钟请求一次更新配置参数
-l 指定监听的端口(default：8080)
```

#### 配置文件参数
```
param - http请求头的Host内容，ss/ssr客户端填写的混淆参数
address - 目标服务的地址和端口(可以本地地址也可以远程地址)
host - 转发后请求头的Host内容(留空则不处理Host)
```

#### json配置文件
```
{
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



