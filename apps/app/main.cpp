#include <mylib/mylib.hpp>

#include <iostream>

int main()
{
    std::cout << mylib::greet("app") << " 2 + 3 = " << mylib::add(2, 3) << '\n';

    mylib::Counter counter;

    for (int value = 1; value <= 10; ++value)
    {
        counter.add(value);
    }

    std::cout << "sum of 1..10 = " << counter.total() << '\n';
    return counter.total() == 55 ? 0 : 1;
}
