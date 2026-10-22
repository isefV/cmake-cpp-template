#include <mylib/mylib.hpp>

#include <raylib.h>

#include <cstdlib>
#include <iostream>
#include <string>
#include <string_view>

int main(int argc, char* argv[])
{
    // --frames <n>: close after n frames (for a quick check); 0: run until the
    // window is closed.
    int maxFrames = 0;
    if (argc == 3 && std::string_view(argv[1]) == "--frames")
    {
        maxFrames = std::atoi(argv[2]);
    }

    const std::string title = mylib::greet("raylib");

    InitWindow(800, 450, "mylib_raylib");
    SetTargetFPS(60);

    Vector2 position{400.0F, 225.0F};
    Vector2 velocity{4.0F, 3.0F};
    constexpr float radius = 24.0F;

    mylib::Counter bounces;

    for (int frame = 0; !WindowShouldClose() && (maxFrames == 0 || frame < maxFrames); ++frame)
    {
        position.x += velocity.x;
        position.y += velocity.y;

        if (position.x < radius || position.x > static_cast<float>(GetScreenWidth()) - radius)
        {
            velocity.x = -velocity.x;
            bounces.add(1);
        }

        if (position.y < radius || position.y > static_cast<float>(GetScreenHeight()) - radius)
        {
            velocity.y = -velocity.y;
            bounces.add(1);
        }

        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawCircleV(position, radius, MAROON);
        DrawText(title.c_str(), 20, 20, 24, DARKGRAY);
        DrawText(TextFormat("bounces: %d", bounces.count()), 20, 54, 20, GRAY);
        DrawFPS(20, 410);
        EndDrawing();
    }

    CloseWindow();

    std::cout << title << " bounces: " << bounces.count() << '\n';
    return 0;
}
