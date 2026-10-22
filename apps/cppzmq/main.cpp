#include <mylib/mylib.hpp>

#include <zmq.hpp>
#include <zmq_addon.hpp>

#include <chrono>
#include <iostream>
#include <iterator>
#include <string>
#include <thread>
#include <vector>

int main()
{
    zmq::context_t context;

    // The subscriber takes only the "value" topic, and sums the values in a
    // mylib::Counter until the "end" topic arrives.
    zmq::socket_t subscriber(context, zmq::socket_type::sub);
    subscriber.bind("inproc://values");
    subscriber.set(zmq::sockopt::subscribe, "value");
    subscriber.set(zmq::sockopt::subscribe, "end");

    mylib::Counter counter;

    std::thread receiver([&subscriber, &counter] {
        for (;;)
        {
            // A message of two parts: topic, value.
            std::vector<zmq::message_t> parts;
            if (!zmq::recv_multipart(subscriber, std::back_inserter(parts)) || parts[0].to_string_view() == "end")
            {
                break;
            }

            counter.add(std::stoi(parts[1].to_string()));
        }
    });

    zmq::socket_t publisher(context, zmq::socket_type::pub);
    publisher.connect("inproc://values");

    // A subscription takes a moment to reach the publisher; until then, its
    // messages are dropped.
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    for (int value = 1; value <= 10; ++value)
    {
        const std::string text = std::to_string(value);
        publisher.send(zmq::str_buffer("value"), zmq::send_flags::sndmore);
        publisher.send(zmq::buffer(text), zmq::send_flags::none);

        publisher.send(zmq::str_buffer("other"), zmq::send_flags::sndmore);    // not subscribed
        publisher.send(zmq::str_buffer("1000"), zmq::send_flags::none);
    }

    publisher.send(zmq::str_buffer("end"), zmq::send_flags::sndmore);
    publisher.send(zmq::str_buffer(""), zmq::send_flags::none);

    receiver.join();

    std::cout << mylib::greet("cppzmq") << " received " << counter.count() << " values, sum = " << counter.total()
              << '\n';
    return counter.total() == 55 ? 0 : 1;
}
