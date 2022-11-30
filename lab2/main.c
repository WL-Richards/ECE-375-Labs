
/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 5 -> Output -> Right Motor Enable
Port B, Pin 4 -> Output -> Right Motor Direction
Port B, Pin 6 -> Output -> Left Motor Enable
Port B, Pin 7 -> Output -> Left Motor Direction
Port D, Pin 5 -> Input -> Left Whisker
Port D, Pin 4 -> Input -> Right Whisker
*/

#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

#define F_CPU 16000000

// Whisker Interrupt Pins
#define WskrR 4				            // Right Whisker Input Bit
#define	WskrL 5				            // Left Whisker Input Bit

// Movement binary representations
#define MovFwd 0b10010000	            // Move Forward Command
#define	MovBck 0b00000000				// Move Backward Command
#define	TurnR  0b10000000			    // Turn Right Command
#define	TurnL  0b00010000			    // Turn Left Command
#define	Halt   0b11110000               // Halt Command

void hit(int wasLeft){
    // Move back for one second
    PORTB = MovBck;
    _delay_ms(1000);
    
    // Depending on whether or not the left side was hit we want to Turn left or right
    PORTB = (wasLeft == 1) ? TurnL : TurnR;
    _delay_ms(1000);

    // Finally continue moving forward
    PORTB = MovFwd;

}

int main(void)
{
    DDRB =  0b11110000;         // Set Port B, pin 5-7 to be in output mode
    DDRD = 0b00000000;          // Set port D to be in output mode
    PORTD = 0b11111111

    while (1){
        // Read the values from pin D
        uint8_t mpr = PIND;
        mpr = mpr & (1<<WskrR|1<<WskrL);

        switch(mpr){

            // If we hit the right whisker
            case (1<<WskrL):

                // Hit was on the left
                hit(1);
                break;
            
            // If we hit the left whisker
            case (1<<WskrR):

                // Hit was on the right
                hit(0);
                break;
        }
    }
}
