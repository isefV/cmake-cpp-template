#include <mylib/mylib.hpp>

#include <taskflow/taskflow.hpp>

#include <array>
#include <iostream>
#include <string>

int main()
{
    constexpr int parts = 4;
    constexpr int last = 1000;

    // One mylib::Counter per task: each task only touches its own.
    std::array<mylib::Counter, parts> partial;
    long long total = 0;

    tf::Executor executor;
    tf::Taskflow taskflow("sum");

    // Four tasks sum a quarter of 1..1000 each, in parallel; then one task
    // adds up their results.
    tf::Task combine = taskflow.emplace([&] {
        for (const auto& counter : partial)
        {
            total += counter.total();
        }
    }).name("combine");

    for (int part = 0; part < parts; ++part)
    {
        tf::Task sum = taskflow.emplace([&partial, part] {
            for (int value = part * last / parts + 1; value <= (part + 1) * last / parts; ++value)
            {
                partial[part].add(value);
            }
        }).name("sum " + std::to_string(part));

        sum.precede(combine);
    }

    executor.run(taskflow).wait();

    std::cout << mylib::greet("Taskflow") << " sum of 1.." << last << " = " << total << " ("
              << executor.num_workers() << " workers)\n";
    return total == 500500 ? 0 : 1;
}
