#include <mylib/mylib.hpp>

#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <GLFW/glfw3.h>     // after the ImGui headers; brings the system OpenGL header

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

    // A window with an OpenGL 3.0 context.
    if (glfwInit() == GLFW_FALSE)
    {
        std::cerr << "GLFW: no window system\n";
        return 1;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    GLFWwindow* window = glfwCreateWindow(960, 600, "mylib_imgui", nullptr, nullptr);
    if (window == nullptr)
    {
        std::cerr << "GLFW: no OpenGL 3.0 window\n";
        glfwTerminate();
        return 1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // ImGui on that window.
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 130");

    const std::string greeting = mylib::greet("ImGui");
    mylib::Counter counter;
    int step = 1;
    bool showDemo = false;

    for (int frame = 0; glfwWindowShouldClose(window) == 0 && (maxFrames == 0 || frame < maxFrames); ++frame)
    {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("mylib");
        ImGui::TextUnformatted(greeting.c_str());
        ImGui::SliderInt("step", &step, 1, 10);

        if (ImGui::Button("Add step"))
        {
            counter.add(step);
        }

        ImGui::SameLine();
        ImGui::Text("total %lld from %d additions", counter.total(), counter.count());
        ImGui::Checkbox("ImGui demo window", &showDemo);
        ImGui::Text("%.1f frames per second", static_cast<double>(ImGui::GetIO().Framerate));
        ImGui::End();

        if (showDemo)
        {
            ImGui::ShowDemoWindow(&showDemo);
        }

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
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    std::cout << greeting << " total: " << counter.total() << '\n';
    return 0;
}
