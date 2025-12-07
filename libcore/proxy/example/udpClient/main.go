package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"strconv"
)

func main() {
	proxyAddr := "127.0.0.1:1080"
	targetAddr := "<YOUR Netcat ip address>:4444"

	// Connect to SOCKS5 proxy
	conn, err := net.Dial("tcp", proxyAddr)
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	// Send greeting to SOCKS5 proxy
	conn.Write([]byte{0x05, 0x01, 0x00})

	// Read greeting response
	response := make([]byte, 2)
	io.ReadFull(conn, response)

	// Send UDP ASSOCIATE request
	conn.Write([]byte{0x05, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

	// Read UDP ASSOCIATE response
	response = make([]byte, 10)
	io.ReadFull(conn, response)

	// Extract the bind address and port
	bindIP := net.IP(response[4:8])
	bindPort := binary.BigEndian.Uint16(response[8:10])

	// Print the bind address
	fmt.Printf("Bind address: %s:%d\n", bindIP, bindPort)

	// Create UDP connection
	udpConn, err := net.Dial("udp", fmt.Sprintf("%s:%d", bindIP, bindPort))
	if err != nil {
		panic(err)
	}
	defer udpConn.Close()

	// Extract target IP and port
	dstIP, dstPortStr, _ := net.SplitHostPort(targetAddr)
	dstPort, _ := strconv.Atoi(dstPortStr)

	// Construct the UDP packet with the target address and message
	packet := make([]byte, 0)
	packet = append(packet, 0x00, 0x00, 0x00) // RSV and FRAG
	packet = append(packet, 0x01)             // ATYP for IPv4
	packet = append(packet, net.ParseIP(dstIP).To4()...)
	packet = append(packet, byte(dstPort>>8), byte(dstPort&0xFF))
	packet = append(packet, []byte("Hello, UDP through SOCKS5!")...)

	// Send the UDP packet
	udpConn.Write(packet)

	// Read the response
	buffer := make([]byte, 1024)
	n, _ := udpConn.Read(buffer)
	fmt.Println("Received:", string(buffer[10:n]))
}
