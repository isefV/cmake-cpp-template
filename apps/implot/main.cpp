#include <mylib/mylib.hpp>

#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <implot.h>

#include <GLFW/glfw3.h>     // after the ImGui headers; brings the system OpenGL header

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>
#include <string_view>
#include <vector>

int main(int argc, char* argv[])
{
    // --frames <n>: close after n frames (for a quick check); 0: run until the
    // window is closed.
    int maxFrames = 0;
    if (argc == 3 && std::string_view(argv[1]) == "--frames")
    {
        maxFrames = std::atoi(argv[2]);
    }

    // A window with an OpenGL 3.0 context.
    if (glfwInit() == GLFW_FALSE)
    {
        std::cerr << "GLFW: no window system\n";
        return 1;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    GLFWwindow* window = glfwCreateWindow(960, 600, "mylib_implot", nullptr, nullptr);
    if (window == nullptr)
    {
        std::cerr << "GLFW: no OpenGL 3.0 window\n";
        glfwTerminate();
        return 1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // ImGui and ImPlot on that window.
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImPlot::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 130");

    // The data: a sine wave, and its running sum kept by a mylib::Counter
    // (values scaled to integers).
    std::vector<double> xs;
    std::vector<double> wave;
    std::vector<double> sums;
    mylib::Counter counter;

    for (int frame = 0; glfwWindowShouldClose(window) == 0 && (maxFrames == 0 || frame < maxFrames); ++frame)
    {
        glfwPollEvents();

        // One new point per frame; the last 600 are shown.
        const double x = frame / 60.0;
        const double y = std::sin(x * 2.0);
        counter.add(static_cast<int>(std::lround(y * 100.0)));

        xs.push_back(x);
        wave.push_back(y);
        sums.push_back(static_cast<double>(counter.total()) / 100.0 / 60.0);

        const int shown = static_cast<int>(xs.size() < 600 ? xs.size() : 600);
        const std::size_t first = xs.size() - static_cast<std::size_t>(shown);

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::SetNextWindowSize(ImVec2(900, 540), ImGuiCond_FirstUseEver);
        ImGui::Begin("mylib + ImPlot");
        ImGui::Text("%d points, counter total %lld", counter.count(), counter.total());

        if (ImPlot::BeginPlot("sin(2x) and its running sum", ImVec2(-1, -1)))
        {
            ImPlot::SetupAxes("x", "y");
            ImPlot::SetupAxisLimits(ImAxis_X1, x - 10.0, x, ImPlotCond_Always);
            ImPlot::SetupAxisLimits(ImAxis_Y1, -1.5, 1.5);
            ImPlot::PlotLine("sin(2x)", &xs[first], &wave[first], shown);
            ImPlot::PlotLine("running sum", &xs[first], &sums[first], shown);
            ImPlot::EndPlot();
        }

        ImGui::End();
        ImGui::Render();

        int width = 0;
        int height = 0;
        glfwGetFramebufferSize(window, &width, &height);
        glViewport(0, 0, width, height);
        glClearColor(0.12F, 0.12F, 0.14F, 1.0F);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImPlot::DestroyContext();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    std::cout << mylib::greet("ImPlot") << " points: " << counter.count() << '\n';
    return 0;
}
