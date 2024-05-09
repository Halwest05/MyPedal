import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.io.IOException;

 
public class Server {
    public static void main(String[] args) throws IOException, AWTException {
        DatagramSocket socket = new DatagramSocket(6969);
        Robot robot = new Robot();

	  System.out.println("\nThis is the pedal system made by halwest!\n\n");

        while(true){
            byte[] buf = new byte[256];
            DatagramPacket packet = new DatagramPacket(buf, buf.length);

            socket.receive(packet);

            String text = new String(packet.getData());

            if(text.contains("d")) {                                                              
                robot.keyPress(KeyEvent.VK_ALT_GRAPH);

		    System.out.println("Sustain pedal down");
            }
            
            else if(text.contains("u")) {
                robot.keyRelease(KeyEvent.VK_ALT_GRAPH);

		    System.out.println("Sustain pedal up");
            }
        }

    }
}