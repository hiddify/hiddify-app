# Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Examples](#examples)
  - [Minimal](#minimal)
  - [Customized](#customized)


## Introduction
The proxy module simplifies connection handling and offers a generic way to work with both HTTP and SOCKS connections,
making it a powerful tool for managing network traffic.


## Features
The Inbound Proxy project offers the following features:

- Full support for `HTTP`, `SOCKS5`, `SOCKS5h`, `SOCKS4` and `SOCKS4a` protocols.
- Handling of `HTTP` and `HTTPS-connect` proxy requests.
- Full support for both `IPv4` and `IPv6`.
- Able to handle both `TCP` and `UDP` traffic.

## Installation

```bash
go get github.com/bepass-org/proxy
```

### Examples

#### Minimal

```go
package main

import (
	"github.com/bepass-org/proxy/pkg/mixed"
)

func main() {
	proxy := mixed.NewProxy()
	_ = proxy.ListenAndServe()
}
```

#### Customized

```go
package main

import (
  "github.com/bepass-org/proxy/pkg/mixed"
)

func main() {
  proxy := mixed.NewProxy(
    mixed.WithBindAddress("0.0.0.0:8080"),
  )
  _ = proxy.ListenAndServe()
}

```

There are other examples provided in the [example](https://github.com/bepass-org/proxy/tree/main/example) directory



