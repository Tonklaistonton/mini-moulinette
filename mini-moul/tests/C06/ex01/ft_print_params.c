#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include "../../../utils/constants.h"
#include "../../../utils/exec_utils.h"

int test1(void);
char* modify_string(const char *str);
static int enter_test_directory(const char *argv0);

int main(int argc, char **argv)
{
  if (argc > 0 && !enter_test_directory(argv[0]))
    return (-1);

  if (test1() != 0)
    return (-1);
  return (0);
}

int test1()
{
  char buf[1024];
  char *program_name = "./program_name"; // Change this to your program name
  char *copy_program = "cp ../../../../ex01/ft_print_params.c program_name.c";
  char *compile_command = "cc -Wall -Werror -Wextra program_name.c -o program_name"; // Change this to the compile command for your program
  char *run_argv[8];
  FILE *fp;
  int result = 0;
  char *args[] = {program_name, "hello\n", "world\n", "123\n", NULL}; // Change these to the arguments you want to pass to the program
  char *run_args[] = {program_name, "hello", "world", "123", NULL};
  int exec_status = 0;
  int i;
  int j;

  if (system(copy_program) != 0 || system(compile_command) != 0)
  {
    printf("    " RED "[1] %s cannot compile\n" DEFAULT, program_name);
    system("rm -f program_name program_name.c");
    return (-1);
  }

  i = 0;
  run_argv[i++] = program_name;
  j = 1;
  while (run_args[j] != NULL && i < 7)
    run_argv[i++] = run_args[j++];
  run_argv[i] = NULL;

  if (capture_command_output((char *const *)run_argv, buf, sizeof(buf), 2,
      &exec_status) != 0)
  {
    printf("    " RED "[1] %s timed out\n" DEFAULT, program_name);
    system("rm -f program_name program_name.c");
    exit(EXIT_FAILURE);
  }

  fp = tmpfile();
  if (fp == NULL)
  {
    fprintf(stderr, "Failed to create temporary stream\n");
    system("rm -f program_name program_name.c");
    exit(EXIT_FAILURE);
  }

  fwrite(buf, 1, strlen(buf), fp);
  rewind(fp);

  i = 1;
  while (fgets(buf, sizeof(buf), fp) != NULL)
  {
    if (args[i] == NULL)
    {
      printf("    " RED "[%d] %s unexpected extra output \"%s\"\n" DEFAULT, i, program_name, modify_string(buf));
      result = -1;
    }
    else if (strcmp(buf, args[i]) != 0)
    {
      printf("    " RED "[%d] %s Expected \"%s\", got \"%s\"\n" DEFAULT, i, program_name, modify_string(args[i]), modify_string(buf));
      result = -1;
    }
    else
    {
      printf("  " GREEN CHECKMARK GREY " [%d] %s Expected \"%s\", got \"%s\"\n" DEFAULT, i, program_name, modify_string(args[i]), modify_string(buf));
      result = 0;
    }
    i++;
  }

  if (args[i] != NULL)
  {
    printf("    " RED "[%d] %s missing output, expected \"%s\"\n" DEFAULT, i, program_name, modify_string(args[i]));
    result = -1;
  }

  fclose(fp);

  if (WIFSIGNALED(exec_status))
  {
    if (WTERMSIG(exec_status) == SIGSEGV)
      printf("    " RED "[%d] %s crashed with segmentation fault\n" DEFAULT, 1, program_name);
    else
      printf("    " RED "[%d] %s crashed with signal %d\n" DEFAULT, 1, program_name, WTERMSIG(exec_status));
    result = -1;
  }
  else if (WIFEXITED(exec_status) && WEXITSTATUS(exec_status) != 0)
  {
    printf("    " RED "[%d] %s exited with status %d\n" DEFAULT, 1, program_name, WEXITSTATUS(exec_status));
    result = -1;
  }

  system("rm -f program_name program_name.c");
  return (result);
}

char* modify_string(const char *str) {
    int len = strlen(str);
    if (len > 0 && str[len - 1] == '\n') {
        char *new_str = (char*)malloc(len);
        strncpy(new_str, str, len - 1);
        new_str[len - 1] = '$';
        return new_str;
    } else {
        return strdup(str);
    }
}

static int enter_test_directory(const char *argv0)
{
  char *path;
  char *slash;

  path = strdup(argv0);
  if (path == NULL)
    return (0);
  slash = strrchr(path, '/');
  if (slash != NULL)
    *slash = '\0';
  else
    strcpy(path, ".");
  if (chdir(path) != 0)
  {
    free(path);
    return (0);
  }
  free(path);
  return (1);
}
