#include <mylib/mylib.hpp>

#include <zmq.h>

#include <iostream>
#include <thread>

int main()
{
    void* context = zmq_ctx_new();

    // The server: replies to two numbers with their sum (mylib::add).
    void* server = zmq_socket(context, ZMQ_REP);
    zmq_bind(server, "inproc://adder");

    std::thread worker([server] {
        for (int request = 0; request < 3; ++request)
        {
            int numbers[2] = {};
            zmq_recv(server, numbers, sizeof numbers, 0);

            const int sum = mylib::add(numbers[0], numbers[1]);
            zmq_send(server, &sum, sizeof sum, 0);
        }
    });

    // The client: sends requests and checks the replies.
    void* client = zmq_socket(context, ZMQ_REQ);
    zmq_connect(client, "inproc://adder");

    int major = 0;
    int minor = 0;
    int patch = 0;
    zmq_version(&major, &minor, &patch);
    std::cout << mylib::greet("ZeroMQ") << " libzmq " << major << '.' << minor << '.' << patch << '\n';

    bool ok = true;

    for (int i = 1; i <= 3; ++i)
    {
        const int numbers[2] = {i, i * 10};
        zmq_send(client, numbers, sizeof numbers, 0);

        int sum = 0;
        zmq_recv(client, &sum, sizeof sum, 0);

        std::cout << numbers[0] << " + " << numbers[1] << " = " << sum << '\n';
        ok = ok && sum == i * 11;
    }

    worker.join();

    zmq_close(client);
    zmq_close(server);
    zmq_ctx_term(context);
    return ok ? 0 : 1;
}
