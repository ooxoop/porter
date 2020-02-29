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
)

var (
	l       string
	r       string
	config	string
)

type Config struct {
	Listen string `json:"listen"`
	Forward []struct {
		Param string `json:"param"`
		Address string `json:"address"`
	} `json:"forward"`
}

var c Config

func init() {
	flag.StringVar(&config, "config", "config.json", "指定配置文件")
	flag.Usage = usage
}

func usage() {
	fmt.Println("Usage: porter -config [jsonFile]\nOptions:")
	flag.PrintDefaults()
}

func main() {
	flag.Parse()
	readJson()

	listen, err := net.Listen("tcp", c.Listen)
	if err != nil {
		return
	}
	fmt.Println("------Porter Start------")
	for {
		accept, err := listen.Accept()
		if err == nil {
			go handler(accept, r)
		}
	}
}

func handler(conn net.Conn, address string) {
	defer conn.Close()
	conn.SetReadDeadline(time.Now().Add(time.Millisecond * time.Duration(5000)))

	p, err := getFirstPacket(conn)
	if err != nil {
		fmt.Println("fail to get first packet")
		return
	}
	if ( strings.Index(string(p), "Host") < 0) {
		fmt.Println("not a http packet")
		return
	}

	host := strings.Split(strings.Split(strings.Split(string(p), "\r\n")[1], ": ")[1], ":")[0]

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
		conn.SetReadDeadline(time.Time{})
		fmt.Println("[", f.Param, "] ---> ", f.Address)
		forward.Write(p)

		go io.Copy(forward, conn)
		io.Copy(conn, forward)
	}
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