package com.newton.espelhartela;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InterfaceAddress;
import java.net.NetworkInterface;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;

public class UdpToggleSender {

    public interface Callback {
        void onResult(boolean ackReceived, String pcIp, String error);
    }

    public static void sendToggle(final String customIp, final int port, final Callback callback) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                DatagramSocket socket = null;
                try {
                    socket = new DatagramSocket();
                    socket.setBroadcast(true);
                    socket.setSoTimeout(1200);

                    byte[] payload = "TOGGLE_CLL".getBytes("UTF-8");
                    List<InetAddress> targets = new ArrayList<InetAddress>();

                    if (customIp != null && !customIp.trim().isEmpty()) {
                        targets.add(InetAddress.getByName(customIp.trim()));
                    }

                    // Add subnet-specific broadcast addresses for active Wi-Fi/LAN interfaces
                    try {
                        Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
                        while (interfaces != null && interfaces.hasMoreElements()) {
                            NetworkInterface nif = interfaces.nextElement();
                            if (nif.isLoopback() || !nif.isUp()) continue;
                            for (InterfaceAddress ia : nif.getInterfaceAddresses()) {
                                InetAddress bcast = ia.getBroadcast();
                                if (bcast instanceof Inet4Address && !targets.contains(bcast)) {
                                    targets.add(bcast);
                                }
                            }
                        }
                    } catch (Exception ignored) {
                    }

                    // Always include global broadcast 255.255.255.255 as fallback
                    InetAddress globalBcast = InetAddress.getByName("255.255.255.255");
                    if (!targets.contains(globalBcast)) {
                        targets.add(globalBcast);
                    }

                    for (InetAddress target : targets) {
                        try {
                            DatagramPacket packet = new DatagramPacket(payload, payload.length, target, port);
                            socket.send(packet);
                        } catch (Exception ignored) {
                        }
                    }

                    // Wait briefly for optional ACK from PC listener
                    byte[] recvBuf = new byte[256];
                    DatagramPacket recvPacket = new DatagramPacket(recvBuf, recvBuf.length);
                    try {
                        socket.receive(recvPacket);
                        String pcIp = recvPacket.getAddress().getHostAddress();
                        if (callback != null) {
                            callback.onResult(true, pcIp, null);
                        }
                        return;
                    } catch (Exception timeoutEx) {
                        // Even if UDP ACK is blocked, the broadcast packet was sent
                        if (callback != null) {
                            callback.onResult(false, null, null);
                        }
                    }
                } catch (Exception e) {
                    if (callback != null) {
                        callback.onResult(false, null, e.getMessage());
                    }
                } finally {
                    if (socket != null) {
                        socket.close();
                    }
                }
            }
        }).start();
    }
}

