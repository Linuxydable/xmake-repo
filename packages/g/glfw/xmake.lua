package("glfw")

    set_homepage("https://www.glfw.org/")
    set_description("GLFW is an Open Source, multi-platform library for OpenGL, OpenGL ES and Vulkan application development.")

    add_urls("https://github.com/glfw/glfw/archive/$(version).tar.gz",
             "https://github.com/glfw/glfw.git")
    add_versions("3.3.2", "98768e12e615fbe9f3386f5bbfeb91b5a3b45a8c4c77159cef06b1f6ff749537")

    add_configs("glfw_include", {description = "Choose submodules enabled in glfw", default = "none", type = "string", values = {"none", "vulkan", "glu", "glext", "es2", "es3"}})

    add_deps("cmake")

    if is_plat("macosx") then
        add_frameworks("Cocoa", "IOKit")
    elseif is_plat("windows") then
        add_syslinks("user32", "shell32", "gdi32")
    elseif is_plat("mingw") then
        add_syslinks("gdi32")
    elseif is_plat("linux") then
        -- TODO: add wayland support
        add_deps("libx11", "libxrandr", "libxrender", "libxinerama", "libxcursor", "libxi", "libxext")
        add_syslinks("dl", "pthread")
        add_defines("_GLFW_X11")
    end

    on_load(function (package)
        package:add("defines", "GLFW_INCLUDE_" .. package:config("glfw_include"):upper())
    end)

    on_install("macosx", "windows", "linux", "mingw", function (package)
        local configs = {"-DGLFW_BUILD_DOCS=OFF", "-DGLFW_BUILD_TESTS=OFF", "-DGLFW_BUILD_EXAMPLES=OFF"}
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        if package:is_plat("windows") and vs_runtime and vs_runtime:startswith("MD") then
            table.insert(configs, "-DUSE_MSVC_RUNTIME_LIBRARY_DLL")
        elseif package:is_plat("linux") then
            -- patch missing libxrender/includes
            local cflags = {}
            local fetchinfo = package:dep("libxrender"):fetch()
            if fetchinfo then
                for _, includedir in ipairs(fetchinfo.includedirs) do
                    table.insert(cflags, "-I" .. includedir)
                end
            end
            if #cflags > 0 then
                table.insert(configs, "-DCMAKE_C_FLAGS=" .. table.concat(cflags, " "))
            end
        end
        import("package.tools.cmake").install(package, configs, {buildir = "build"})
        if package:is_plat("windows", "mingw") and package:config("shared") then
            os.trycp("build/install/bin", package:installdir())
            package:addenv("PATH", "bin")
        end
    end)

    on_test(function (package)
        assert(package:check_csnippets({test = [[
            void test() {
                glfwInit();
                glfwTerminate();
            }
        ]]}, {configs = {languages = "c11"}, includes = "GLFW/glfw3.h"}))
    end)
