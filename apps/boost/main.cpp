#include <mylib/mylib.hpp>

#include <boost/program_options.hpp>

#include <iostream>

namespace po = boost::program_options;

int main(int argc, char* argv[])
{
    po::options_description options("mylib_boost: sums the numbers from --from to --to");
    options.add_options()
        ("help,h", "show this help")
        ("from", po::value<int>()->default_value(1), "first number")
        ("to", po::value<int>()->default_value(10), "last number");

    po::variables_map args;

    try
    {
        po::store(po::parse_command_line(argc, argv, options), args);
        po::notify(args);
    }
    catch (const po::error& error)
    {
        std::cerr << error.what() << '\n' << options;
        return 2;
    }

    if (args.count("help") != 0)
    {
        std::cout << options;
        return 0;
    }

    const int from = args["from"].as<int>();
    const int to = args["to"].as<int>();

    mylib::Counter counter;

    for (int value = from; value <= to; ++value)
    {
        counter.add(value);
    }

    // The same sum, by Gauss's formula.
    const long long expected = to < from ? 0 : (static_cast<long long>(from) + to) * (to - from + 1) / 2;

    std::cout << mylib::greet("Boost") << " sum of " << from << ".." << to << " = " << counter.total() << '\n';
    return counter.total() == expected ? 0 : 1;
}
