#include <mylib/mylib.hpp>

#include <nlohmann/json.hpp>

#include <iostream>
#include <vector>

int main()
{
    const std::vector<int> values{3, 5, 7, 11};

    mylib::Counter counter;

    for (int value : values)
    {
        counter.add(value);
    }

    // Write: a JSON object from plain C++ values.
    const nlohmann::json result = {
        {"greeting", mylib::greet("JSON")},
        {"values", values},
        {"count", counter.count()},
        {"total", counter.total()},
    };

    const std::string text = result.dump(2);
    std::cout << text << '\n';

    // Read: parse the text again and take the values out.
    const auto parsed = nlohmann::json::parse(text);
    const auto readValues = parsed.at("values").get<std::vector<int>>();
    const auto readTotal = parsed.at("total").get<long long>();

    return readValues == values && readTotal == 26 ? 0 : 1;
}
