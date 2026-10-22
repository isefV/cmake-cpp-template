#include <mylib/mylib.hpp>

#include <boost/sml.hpp>

#include <iostream>

namespace sml = boost::sml;

namespace
{
    // Events
    struct coin
    {
        int cents;
    };

    struct push
    {
    };

    // A turnstile: locked until a coin is paid, unlocked until pushed through.
    // The coins go into a mylib::Counter, passed in as a dependency.
    struct turnstile
    {
        auto operator()() const
        {
            using namespace sml;

            const auto pay = [](const coin& event, mylib::Counter& cash) { cash.add(event.cents); };
            const auto alarm = [] { std::cout << "  push while locked: alarm\n"; };

            // clang-format off
            return make_transition_table(
                *"locked"_s   + event<coin> / pay   = "unlocked"_s,
                 "locked"_s   + event<push> / alarm,
                 "unlocked"_s + event<coin> / pay,
                 "unlocked"_s + event<push>         = "locked"_s
            );
            // clang-format on
        }
    };
} // namespace

int main()
{
    using namespace sml;

    mylib::Counter cash;
    sm<turnstile> machine{cash};

    const auto state = [&machine] { return machine.is("locked"_s) ? "locked" : "unlocked"; };

    std::cout << mylib::greet("SML") << " start: " << state() << '\n';

    machine.process_event(push{});
    machine.process_event(coin{50});
    std::cout << "after a coin: " << state() << '\n';

    machine.process_event(coin{20});
    machine.process_event(push{});
    std::cout << "after a push: " << state() << '\n';

    std::cout << "cash: " << cash.total() << " cents from " << cash.count() << " coins\n";
    return machine.is("locked"_s) && cash.total() == 70 ? 0 : 1;
}
