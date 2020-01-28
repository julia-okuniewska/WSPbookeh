#define GLEW_STATIC
#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

#define ASSERT(x) if (!(x))
#define GLCall(x) GLClearError();\
	x;\
	ASSERT(GLLogCall(#x, __FILE__, __LINE__))

static void GLClearError()
{
	while (glGetError() != GL_NO_ERROR);
}

static bool GLLogCall(const char* function, const char* file, int line)
{
	while (GLenum error = glGetError())
	{
		std::cout << " [OpenGL error] (" << error << ")" << function <<
			" "<< file << ": " << line << std::endl;

		return false;
	}
	return true;
}

struct ShaderProgramSource
{
	std::string VertexSource;
	std::string FragmentSource;
	
};


static ShaderProgramSource ParseShader(const std::string& filepath)
{
	std::ifstream stream(filepath);

	enum class ShaderType
	{
		NONE = -1, VERTEX = 0, FRAGMENT = 1
	};

	std::string line;
	std::stringstream ss[2];
	ShaderType type = ShaderType::NONE;
	while (getline(stream, line))
	{
		if (line.find("#shader") != std::string::npos)
		{
			if (line.find("vertex") != std::string::npos)
				type = ShaderType::VERTEX;
			else if (line.find("fragment") != std::string::npos)
				type = ShaderType::FRAGMENT;
		}
		else
		{
			if (type != ShaderType::NONE)
			{
				ss[(int)type] << line << "\n";
			}	

		}
	}
	return { ss[0].str(), ss[1].str() };

}

static unsigned int CompileShader(unsigned int type, const std::string& source)
{
	unsigned int id = glCreateShader(type);
	const char* src = source.c_str();
	glShaderSource(id, 1, &src, nullptr);
	glCompileShader(id);
	

	int result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE)
	{
		int length;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
		char* message = (char*)alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);

		std::cout << "Failed to compile"
			<< (type == GL_VERTEX_SHADER ? "vertex" : "fragment")
			<< std::endl;

		std::cout << message << std::endl;
		glDeleteShader(id);
		return 0;

	}

	return id;

}


static int CreateShader(const std::string& vertexShader, const std::string& fragmentShader)
{
	unsigned int program = glCreateProgram();
	unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
	unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);
	glValidateProgram(program);

	glDeleteShader(vs);
	glDeleteShader(fs);

	return program;
}

int main(void)
{
		GLFWwindow* window;

		/* Initialize the library */
		if (!glfwInit())
			return -1;

		/* Create a windowed mode window and its OpenGL context */
		window = glfwCreateWindow(640, 480, "Hello World", NULL, NULL);
		if (!window)
		{
			glfwTerminate();
			return -1;
		}

		/* Make the window's context current */
		glfwMakeContextCurrent(window);

		if (glewInit() != GLEW_OK)
			std::cout << "GLEW error!" << std::endl;

		//std::cout << glGetString(GL_VERSION) << std::endl;

		float positions[] = {
			-0.5f, -0.5f,
			 0.5f, -0.5f,
			 0.5f,  0.5f,
			 -0.5f,  0.5f,
		};

		unsigned int indicies[] = {
		0, 1, 2,
		2, 3,0
		};

		unsigned int buffer;
		glGenBuffers(1, &buffer);
		glBindBuffer(GL_ARRAY_BUFFER, buffer);
		glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), positions, GL_STATIC_DRAW);

		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);

		unsigned int ibo; 
		glGenBuffers(1, &ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(unsigned int), indicies, GL_STATIC_DRAW);


		ShaderProgramSource source = ParseShader("res/shaders/Basic.shader");

		std::cout << "VERTEX" << std::endl;
		std::cout << source.VertexSource << std::endl;
		std::cout << "FRAGMENT" << std::endl;
		std::cout << source.FragmentSource << std::endl;

		unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
		glUseProgram(shader);

		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		

		/* Loop until the user closes the window */
		while (!glfwWindowShouldClose(window))
		{
			/* Render here */
			glClear(GL_COLOR_BUFFER_BIT);

			glDisable(GL_CULL_FACE);
			//glDrawArrays(GL_TRIANGLES, 0, 6);
			GLCall(glDrawElements(GL_TRIANGLES, 6, GL_INT, nullptr));
			
			float baseX = 0.0f;
			float baseY = 0.0f;
			float stage = (3.14 * 2.f) / 70.f;
			float radius = 0.3f;
			glLineWidth(4.0);

			glBegin(GL_TRIANGLE_FAN);
			glVertex2f(baseX, baseY);
			for (float tempAngle = 0.0f; tempAngle <= 3.14 * 2.01f; tempAngle += stage) {
				float x = baseX + radius * cos(tempAngle);
				float y = baseY + radius * sin(tempAngle);
				glVertex2f(x, y);
			}

			glEnd();
			baseX = 0.5f;
			baseY = 0.5f;

			glBegin(GL_TRIANGLE_FAN);
			glVertex2f(baseX, baseY);
			for (float tempAngle = 0.0f; tempAngle <= 3.14 * 2.01f; tempAngle += stage) {
				float x = baseX + radius * cos(tempAngle);
				float y = baseY + radius * sin(tempAngle);
				glVertex2f(x, y);
			}

			glEnd();

			/* Swap front and back buffers */
			glfwSwapBuffers(window);

			/* Poll for and process events */
			glfwPollEvents();
		}

		glDeleteProgram(shader);

		glfwTerminate();
		return 0;
}

