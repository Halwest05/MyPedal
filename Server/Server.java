import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.KeyEvent;
import java.io.IOException;

public class Server {
    public static void main(String[] args) throws IOException, AWTException {
        DatagramSocket socket = new DatagramSocket(6969, InetAddress.getByName("192.168.0.107"));
        Robot robot = new Robot();

        while(true){
            byte[] buf = new byte[256];
            DatagramPacket packet = new DatagramPacket(buf, buf.length);

            socket.receive(packet);

            String text = new String(packet.getData());

            System.out.println(text);

            if(text.contains("d")) {                                                              
                robot.keyPress(KeyEvent.VK_SPACE);
                robot.keyRelease(KeyEvent.VK_SPACE);
            }

            else if(text.contains("u")) {
                robot.keyPress(KeyEvent.VK_SPACE);
                robot.keyRelease(KeyEvent.VK_SPACE);
            }
        }
    }
}