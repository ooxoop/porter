package main

import (
	"fmt"
	"net"
	"time"
	"io"
	"strings"
	"flag"
	"os"
	"encoding/json"
	"bytes"
	"io/ioutil"
    "net/http"
)

var (
	l  string
	config	string
)

type Config struct {
	Forward []struct {
		Param string `json:"param"`
		Address string `json:"address"`
		Host string `json:"host"`
	} `json:"forward"`
	SSH string `json:"ssh"`
}

var c Config

func init() {
	flag.StringVar(&config, "config", "config.json", "指定配置文件/url")
	flag.StringVar(&l, "l", "8080", "指定监听端口")
	flag.Usage = usage
}

func usage() {
	fmt.Println("Usage: porter -config [jsonFile]\nOptions:")
	flag.PrintDefaults()
}

func main() {
	flag.Parse()


	//fmt.Println([]byte("\r\n")[0])
	if strings.Index(config, "http://") > -1 || strings.Index(config, "https://") > -1 {
		go func() {
			for true {
				getJson()
				time.Sleep(time.Duration(60)*time.Second)
			}
		}()
	} else {
		readJson()
	}

	listen, err := net.Listen("tcp", ":"+l)
	
	if err != nil {
		return
	}
	fmt.Println("[Porter] Start Listening on", l)
	for {
		accept, err := listen.Accept()
		if err == nil {
			go handler(accept)
		}
	}
}

func handler(conn net.Conn) {
	defer conn.Close()
	conn.SetReadDeadline(time.Now().Add(time.Millisecond * time.Duration(5000)))

	p, err := getFirstPacket(conn)
	if err != nil {
		fmt.Println("fail to get first packet")
		return
	}

	if ( string(p)[:3] == "SSH" ) {   
		fmt.Println("SSH packet")
		sshForward(conn, p)
		return
	}
	if ( strings.Index(string(p), "Host") < 0) {
		fmt.Println("not a http packet")
		return
	}

	host := strings.Split(strings.Split(strings.Split(string(p), "\r\n")[1], ": ")[1], ":")[0]
	flag := false

	for _, f := range c.Forward {
		if ( host != f.Param ) {
			continue
		}
		forward, err := net.Dial("tcp", f.Address)
		if err != nil {
			fmt.Println("connect failed: ", err)
			return
		}
		defer forward.Close()

		if f.Host != "" {
			p = HostInject(p, f.Host)
		}

		conn.SetReadDeadline(time.Time{})
		fmt.Println("[", f.Param, "] ----> ", f.Address)
		forward.Write(p)

		go io.Copy(forward, conn)
		io.Copy(conn, forward)
		flag = true
		break
	}
	if !flag {
		fmt.Println("[", host, "] --x-- ")
	}
}

func sshForward(conn net.Conn, p []byte) {
	forward, err := net.Dial("tcp", c.SSH)
	if err != nil {
		fmt.Println("connect failed: ", err)
		return
	}
	defer forward.Close()
	conn.SetReadDeadline(time.Time{})
	forward.Write(p)
	go io.Copy(forward, conn)
	io.Copy(conn, forward)
}

func HostInject(p []byte, host string) []byte {
	var i int
	flag := 0
	for i=0; i<len(p); i++ {
		if p[i] == 13 && p[i+1] == 10 {
			flag++
		}
		if flag == 2 {
			flag = i-1
			break
		}
	}
	strs := strings.Split(string(p[:i]), "\r\n")
	strs[1] = "Host: " + host
	b := []byte(strings.Join(strs, "\r\n"))
	return BytesCombine(b, p[i:])
}

func BytesCombine(pBytes ...[]byte) []byte {
    return bytes.Join(pBytes, []byte(""))
}

func getFirstPacket(conn net.Conn) ([]byte, error) {
	buf := make([]byte, 2048)
	n, err := conn.Read(buf)
	if err != nil {
		return nil, err
	}
	return buf[:n], nil
}

func readJson() {
    file, err := os.Open(config)
    if err != nil {
        fmt.Println("Open file failed [Err:%s]", err.Error())
        return
    }
    defer file.Close()
    decoder := json.NewDecoder(file)
    err = decoder.Decode(&c)
    if err != nil {
        fmt.Println("Read json failed", err.Error())
    } else {
        fmt.Println("Read json succeed")
    }
}

func getJson() {
	timeout := time.Duration(10 * time.Second)
	client := &http.Client{Timeout: timeout}
	req, _ := http.NewRequest("GET", config, nil)
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("请求失败")
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("读取返回数据失败")
		return
	}
	json.Unmarshal(body,&c)
}