#include <avr/io.h>
#include <avr/interrupt.h>
#include <inttypes.h>

//INPUT PINS digital 2-7 PIND
#define PIND_MASK B11111100
//INPUT PINS digitat 8-12 PINB
#define PINB_MASK B00011111
//INPUT PINS analog 0-4 PINC
#define PINC_MASK B00011111

#define INPUT_SIG_PORTD B11000000
#define INPUT_SIG_PORTB B00011111
#define INPUT_SIG_PORTC B00010000

#define OUTPUT_SIG_PORTB ( PINB_MASK & ~INPUT_SIG_PORTB )
// B00011111 & ! B00011111 = 0
#define OUTPUT_SIG_PORTC ( PINC_MASK & ~INPUT_SIG_PORTC )
// B00011111 & ! B00010000 = B00001111
#define OUTPUT_SIG_PORTD ( PIND_MASK & ~INPUT_SIG_PORTD )
// B11111100 & ! B11000000 = 00111100
union union16 {
  byte uint8[2];
  uint16_t uint16;
}; 

union union32 {
  byte uint8[4];
  uint16_t uint16[2];
  uint32_t uint32;
}; 


//********************************************************************//

typedef unsigned char byte;

//********************************************************************//
/*
void start_timer()
{
  // timer 1: 2 ms
  TCCR1A = 0;                    // prescaler 1:8, WGM = 4 (CTC)
  TCCR1B = 1<<WGM12 | 1<<CS11;   // 
  OCR1A = 159;        // (1+159)*8 = 1280 -> 0.08ms @ 16 MHz -> 1*alpha
//  OCR1A = 207;        // (1+207)*8 = 1664 -> 0.104ms @ 16 MHz -> 1*alpha
  TCNT1 = 0;          // reseting timer
  TIMSK1 = 1<<OCIE1A; // enable Interrupt
}

void stop_timer() // stop the timer
{
  // timer1
  TCCR1B = 0; // no clock source
  TIMSK1 = 0; // disable timer interrupt
}
*/
byte last_input=0;
byte last_output=0;
static void PCint(uint8_t port) {
  byte input = ( INPUT_SIG_PORTB  & ~ PINB ) | ( ( INPUT_SIG_PORTC  & ~ PINC ) <<1 ) |( INPUT_SIG_PORTD  & ~ PIND );
  byte output = ( OUTPUT_SIG_PORTC  & ~ PINC ) | (( OUTPUT_SIG_PORTD  & ~ PIND ) <<2 ); // no output on B 
 
  if (!input)
   return;
  if (last_input==input && last_output==output)
    return;
  last_input=input;
  last_output=output;
  Serial.print(output,HEX);
  Serial.print('\t');
  Serial.println(input,HEX);
  return;
}



SIGNAL(PCINT0_vect) {
  PCint(0);
}
SIGNAL(PCINT1_vect) {
  PCint(1);
}
SIGNAL(PCINT2_vect) {
  PCint(2);
}
void setup()
{
//  pinMode(RF433_PIN, INPUT);      // set pin to input
//  digitalWrite(RF433_PIN, LOW);  // turn of pullup resistors 
  //Set Port as input
  DDRB=0;
// disable pull up
  PORTB=0;
  DDRD = DDRD & 3;
  PORTD= PORTD & 3;

  DDRC=0;
  PORTC=0;
  Serial.begin(57600);
  //Serial.println("starting timer");
  PCMSK0=PINB_MASK & INPUT_SIG_PORTB;
  PCMSK1=PINC_MASK & INPUT_SIG_PORTC;
  PCMSK2=PIND_MASK & INPUT_SIG_PORTD;
  PCICR|= B111;

//  start_timer();
}


//INPUT PINS digital 2-7 PIND
//INPUT PINS digitat 8-12 PINB
//INPUT PINS analog 0-4 PINC
void loop()
{
//  Serial.Serial.println("foo");
//  return;


}
