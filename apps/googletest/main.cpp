#include <mylib/mylib.hpp>

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <ostream>
#include <utility>

// main() comes from GTest::gmock_main.

// A fixture: every TEST_F gets a fresh Counter.
class CounterTest : public ::testing::Test
{
protected:
    mylib::Counter counter;
};

TEST_F(CounterTest, StartsEmpty)
{
    EXPECT_EQ(counter.total(), 0);
    EXPECT_EQ(counter.count(), 0);
}

TEST_F(CounterTest, SumsWhatItIsGiven)
{
    counter.add(4);
    counter.add(-1);

    EXPECT_EQ(counter.total(), 3);
    EXPECT_EQ(counter.count(), 2);
}

TEST_F(CounterTest, MovesItsTotal)
{
    counter.add(7);
    mylib::Counter moved = std::move(counter);

    EXPECT_EQ(moved.total(), 7);
}

// A parameterized test: one test per row.
struct AddCase
{
    int a;
    int b;
    int sum;
};

// How GoogleTest prints a row: in failure messages and in the CTest names.
std::ostream& operator<<(std::ostream& out, const AddCase& row)
{
    return out << row.a << " + " << row.b << " = " << row.sum;
}

class AddTest : public ::testing::TestWithParam<AddCase>
{
};

TEST_P(AddTest, Adds)
{
    const auto [a, b, sum] = GetParam();
    EXPECT_EQ(mylib::add(a, b), sum);
}

INSTANTIATE_TEST_SUITE_P(
    Rows,
    AddTest,
    ::testing::Values(AddCase{1, 2, 3}, AddCase{-4, 4, 0}, AddCase{100, -1, 99}));

// GoogleMock matchers: say what a value must look like.
TEST(Greet, NamesTheCaller)
{
    using ::testing::AllOf;
    using ::testing::EndsWith;
    using ::testing::HasSubstr;
    using ::testing::StartsWith;

    EXPECT_THAT(mylib::greet("GoogleTest"), AllOf(StartsWith("Hello"), HasSubstr("GoogleTest"), EndsWith("!")));
}
