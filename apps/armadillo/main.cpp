#include <mylib/mylib.hpp>

#include <armadillo>

#include <iostream>

// Only operations that need no LAPACK, so this runs with every Armadillo
// build; with LAPACK, arma::solve(), arma::inv(), arma::eig_sym() work too.
int main()
{
    std::cout << mylib::greet("Armadillo") << " version " << arma::arma_version::as_string() << '\n';

    const arma::mat a = {{1, 2}, {3, 4}};
    const arma::mat b = a * a.t();
    b.print("a * a.t() =");

    // 1, 2, ..., 10 as a vector; Armadillo's sum and mylib's must agree.
    const arma::vec values = arma::regspace(1, 10);

    mylib::Counter counter;

    for (double value : values)
    {
        counter.add(static_cast<int>(value));
    }

    std::cout << "accu = " << arma::accu(values) << ", mylib = " << counter.total() << '\n';

    const bool ok = b(0, 0) == 5 && b(1, 1) == 25 && arma::accu(values) == static_cast<double>(counter.total());
    return ok ? 0 : 1;
}
