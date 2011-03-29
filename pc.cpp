#include <iostream>

int main()
{
  unsigned char c =0;
  unsigned char sym =0;
  int counter = 1000;
  while( counter--)
  {
    std::cin >> c;
    for(int i = 0; i<8; i++)
    {
      sym = c & (1<<7);
      if( sym)
      {
        std::cout << "1,";
      } else {
        std::cout << "0,";
      }
      c<<=1;
    }
  }
}
