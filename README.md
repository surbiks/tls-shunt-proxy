# TLS Shunt Proxy

Used for shunting TLS traffic, suitable for vmess + TLS + Web solutions, and can share ports with Trojan.
* SNI Shunting
* HTTP and Unspecified Traffic Shunting
* Static Website Server
* Automatic Certificate Acquisition

## Download and Installation
For linux-amd64, you can use the script installation. Execute the following command as root:
```shell
bash <(curl -L -s https://raw.githubusercontent.com/surbiks/tls-shunt-proxy/master/dist/install.sh)
```
* Configuration file is located at `/etc/tls-shunt-proxy/config.yaml`

* Other platforms need to compile and install manually.

## Usage
Command line parameters:
```
  -config string
        Path to config file (default "./config.yaml")
```

<details>
  <summary>Click here to expand the example configuration file</summary>
  
```yml
# listen: Listening address
listen: 0.0.0.0:443

# redirecthttps: Listening for an address, HTTP requests sent to this address will be redirected to HTTPS
redirecthttps: 0.0.0.0:80

# inboundbuffersize: Inbound buffer size in KB, default is 4
# With the same throughput and connection count, a larger buffer consumes more memory and less CPU time. A large cache may increase latency in cases of low network throughput.
inboundbuffersize: 4

# outboundbuffersize: Outbound buffer size in KB, default is 32
outboundbuffersize: 32

# vhosts: Divided into multiple virtual hosts based on the TLS SNI extension
vhosts:

    # name corresponds to the server name in the TLS SNI extension
  - name: vmess.example.com

    # tlsoffloading: Unload TLS, true to unload, which can identify HTTP traffic, suitable for vmess over TLS and HTTP over TLS (HTTPS) shunting, etc.
    tlsoffloading: true

    # managedcert: Manage certificates, when enabled, will automatically acquire a certificate from Let's Encrypt. To get issued, it must listen on port 443 according to Let's Encrypt requirements.
    # When enabled, the cert and key set certificates are invalid; when disabled, the cert and key configured certificates will be used.
    managedcert: false

    # keytype: Key pair type generated when managedcert is enabled. Supported options: ed25519, p256, p384, rsa2048, rsa4096, rsa8192
    keytype: p256

    # cert: Path to the TLS certificate,
    cert: /etc/ssl/vmess.example.com.pem

    # key: Path to the TLS private key
    key: /etc/ssl/vmess.example.com.key

    # alpn: ALPN, separate multiple next protocols with ","
    alpn: h2,http/1.1

    # protocols: Specify TLS protocol version in the format min,max, available values are tls12 (default min), tls13 (default max)
    # If min and max are the same, you only need to write it once.
    # tls12 only supports FS and AEAD cipher suites.
    protocols: tls12,tls13

    # http: Handling of identified HTTP traffic
    http:

      # paths: Shunt based on HTTP request paths, matching from top to bottom. If no matches are found, the HTTP handler will be used.
      # path: Requests with this string prefix will apply this handler
        - path: /vmess/ws/
          handler: proxyPass
          args: 127.0.0.1:40000

          # path: HTTP/2 requests will be recognized as *
        - path: "*"
          handler: proxyPass
          args: 127.0.0.1:40003

        - path: /static/

          # trimprefix: Trim the prefix, when handing HTTP traffic to the handler, it will trim the prefix from the path.
          # For example, it will trim /static/logo.jpg to /logo.jpg
          trimprefix: /static

          handler: fileServer
          args: /var/www/static

      # handler: fileServer will serve a static website
      # fileServer supports h2c. If using fileServer to handle HTTP, and no paths are set, alpn can enable h2.
      handler: fileServer

      # args: Path to the static website files
      args: /var/www/html
      
    # HTTP/2 request handling method. When this is set, the path: "*" setup in HTTP will be invalid.
    http2:
      - path: /
        handler: fileServer
        args: /var/www/rayfantasy
      - path: /vmess
        handler: proxyPass
        # Currently, only targets accepting h2c are supported.
        args: h2c://localhost:40002

    # trojan: Handling method for Trojan protocol traffic
    trojan:
      handler: proxyPass
      args: 127.0.0.1:4430

    # default: Handling method for other traffic
    default:

      # handler: proxyPass will forward traffic to another address
      handler: proxyPass

      # args: Target address for forwarding
      args: 127.0.0.1:40001

      # args: Supports passing the source address to the backend through Proxy Protocol, currently only supports v1
      # args: 127.0.0.1:40001;proxyProtocol

      # args: You can also use a domain socket
      # args: unix:/path/to/ds/file

  - name: trojan.example.com

    # tlsoffloading: Unload TLS, false to not unload, directly handle TLS traffic, suitable for Trojan-GFW, etc.
    tlsoffloading: false

    # default: When tlsoffloading is disabled, there are currently no recognition methods, and all are handled as other traffic.
    default:
      handler: proxyPass
      args: 127.0.0.1:8443

```
</details>

## Troubleshooting and Common Issues
1. If the service fails to start, use the command `sudo setcap "cap_net_bind_service=+ep" /usr/local/bin/tls-shunt-proxy` to grant the tls-shunt-proxy capability to bind to network services, then run `sudo -u tls-shunt-proxy /usr/local/bin/tls-shunt-proxy -config /etc/tls-shunt-proxy/config.yaml` to obtain error information.

2. `fail to load tls key pair for xxx.xxx: open /xxx/xxx.key: permission denied` Ensure the user `tls-shunt-proxy` has permission to read the certificate.