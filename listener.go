package main

import (
	"bytes"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

func baseDir() string {
	exe, err := os.Executable()
	if err != nil {
		return "."
	}
	return filepath.Dir(exe)
}

func logEvent(format string, args ...interface{}) {
	logFile := filepath.Join(baseDir(), "espelhar.log")
	f, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return
	}
	defer f.Close()
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(f, "[%s] %s\n", timestamp, fmt.Sprintf(format, args...))
}

func isRunning() bool {
	cmd := exec.Command("tasklist", "/FI", "IMAGENAME eq scrcpy.exe", "/NH")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	var out bytes.Buffer
	cmd.Stdout = &out
	_ = cmd.Run()
	return strings.Contains(strings.ToLower(out.String()), "scrcpy.exe")
}

func savePhoneIP(phoneIP string) {
	if phoneIP == "" || phoneIP == "127.0.0.1" || phoneIP == "::1" {
		return
	}
	ipPath := filepath.Join(baseDir(), "phone_ip.txt")
	_ = os.WriteFile(ipPath, []byte(strings.TrimSpace(phoneIP)), 0644)
	logEvent("phone_ip.txt atualizado com o IP: %s", phoneIP)
}

func main() {
	if len(os.Args) > 1 {
		arg := strings.ToLower(os.Args[1])
		if arg == "--toggle" || arg == "-t" || arg == "toggle" {
			conn, err := net.Dial("udp", "127.0.0.1:8888")
			if err == nil {
				_, _ = conn.Write([]byte("TOGGLE_CLL"))
				_ = conn.Close()
				return
			}
			// Fallback if background daemon is offline
			if isRunning() {
				killCmd := exec.Command("taskkill", "/F", "/IM", "scrcpy.exe")
				killCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
				_ = killCmd.Run()
				discCmd := exec.Command("adb", "disconnect")
				discCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
				_ = discCmd.Run()
			} else {
				vbsPath := filepath.Join(baseDir(), "invisivel.vbs")
				_ = exec.Command("wscript", vbsPath).Start()
			}
			return
		}
	}

	addr := net.UDPAddr{Port: 8888, IP: net.ParseIP("0.0.0.0")}
	conn, err := net.ListenUDP("udp4", &addr)
	if err != nil {
		logEvent("Erro ao escutar porta UDP 8888: %v", err)
		return
	}
	defer conn.Close()
	logEvent("Ouvinte UDP ativo na porta 8888")

	buf := make([]byte, 1024)
	var lastTrigger time.Time

	for {
		n, remoteAddr, err := conn.ReadFromUDP(buf)
		if err != nil {
			continue
		}
		msg := strings.TrimSpace(string(buf[:n]))

		if msg == "PING_ESPELHAR" && remoteAddr != nil {
			_, _ = conn.WriteToUDP([]byte("PONG_ESPELHAR"), remoteAddr)
			continue
		}

		if strings.HasPrefix(msg, "TOGGLE_CLL") {
			if time.Since(lastTrigger) < 1500*time.Millisecond {
				continue
			}
			lastTrigger = time.Now()

			senderIP := ""
			if remoteAddr != nil && remoteAddr.IP != nil {
				senderIP = remoteAddr.IP.String()
				savePhoneIP(senderIP)
				_, _ = conn.WriteToUDP([]byte("OK_TOGGLE"), remoteAddr)
			}

			logEvent("TOGGLE_CLL acionado (origem: %s)", senderIP)

			if isRunning() {
				logEvent("Fechando scrcpy...")
				killCmd := exec.Command("taskkill", "/F", "/IM", "scrcpy.exe")
				killCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
				_ = killCmd.Run()

				discCmd := exec.Command("adb", "disconnect")
				discCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
				_ = discCmd.Run()
			} else {
				logEvent("Iniciando invisivel.vbs...")
				vbsPath := filepath.Join(baseDir(), "invisivel.vbs")
				cmd := exec.Command("wscript", vbsPath)
				cmd.Dir = baseDir()
				_ = cmd.Start()
			}
		}
	}
}
