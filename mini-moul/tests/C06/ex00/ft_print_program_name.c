#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include "../../../utils/constants.h"
#include "../../../utils/exec_utils.h"

typedef struct s_test
{
  char *desc;
  char **argv;
  char *expected;
} t_test;

int run_test(t_test test, int test_num);
char *modify_string(const char *str);
static int enter_test_directory(const char *argv0);

int main(int argc, char **argv)
{
  if (argc > 0 && !enter_test_directory(argv[0]))
    return (-1);

  t_test tests[] = {
      {.desc = "ft_print_program_name with one argument",
       .argv = (char *[]){"program_name", NULL},
       .expected = "./program_name\n"},
      {.desc = "ft_print_program_name with multiple arguments",
       .argv = (char *[]){"program_name", "arg1", "arg2", NULL},
       .expected = "./program_name\n"},
      {.desc = "ft_print_program_name with no arguments",
       .argv = (char *[]){"NULL"},
       .expected = "./program_name\n"},
      {.desc = "ft_print_program_name with empty string",
       .argv = (char *[]){""},
       .expected = "./program_name\n"},
      {.desc = "ft_print_program_name with long argument",
       .argv = (char *[]){"program_name", "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", NULL},
       .expected = "./program_name\n"},
  };

  int num_tests = sizeof(tests) / sizeof(t_test);

  int overall_result = 0;

  for (int i = 0; i < num_tests; i++)
  {
    int result = run_test(tests[i], i + 1);

    if (result != 0)
    {
      overall_result = -1;
    }
  }

  return overall_result;
}

int run_test(t_test test, int test_num)
{
  char buf[1024];
  char *program_name = "./program_name";
  char *copy_program = "cp ../../../../ex00/ft_print_program_name.c program_name.c";
  char *compile_command = "cc -Wall -Werror -Wextra program_name.c -o program_name";
  char *run_argv[8];
  FILE *fp;
  int result = 0;
  int exec_status = 0;
  int i;
  int j;

  if (system(copy_program) != 0 || system(compile_command) != 0)
  {
    printf("    " RED "[%d] %s cannot compile\n" DEFAULT, test_num, test.desc);
    system("rm -f program_name program_name.c");
    return (-1);
  }

  i = 0;
  run_argv[i++] = program_name;
  j = 1;
  while (test.argv[j] != NULL && i < 7)
    run_argv[i++] = test.argv[j++];
  run_argv[i] = NULL;

  if (capture_command_output((char *const *)run_argv, buf, sizeof(buf), 2,
      &exec_status) != 0)
  {
    printf("    " RED "[%d] %s timed out\n" DEFAULT, test_num, test.desc);
    system("rm -f program_name program_name.c");
    return (-1);
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
  while (fgets(buf, sizeof(buf), fp) != NULL)
  {
    if (strcmp(buf, test.expected) != 0)
    {
      printf("    " RED "[%d] %s Expected \"%s\", got \"%s\"\n" DEFAULT, test_num, test.desc, test.expected, modify_string(buf));
      result = -1;
    }
    else
    {
      printf("  " GREEN CHECKMARK GREY " [%d] %s output \"%s\" as expected\n" DEFAULT, test_num, test.desc, modify_string(buf));
      result = 0;
    }
  }
  fclose(fp);

  if (WIFSIGNALED(exec_status))
  {
    if (WTERMSIG(exec_status) == SIGSEGV)
      printf("    " RED "[%d] %s crashed with segmentation fault\n" DEFAULT, test_num, test.desc);
    else
      printf("    " RED "[%d] %s crashed with signal %d\n" DEFAULT, test_num, test.desc, WTERMSIG(exec_status));
    result = -1;
  }
  else if (WIFEXITED(exec_status) && WEXITSTATUS(exec_status) != 0)
  {
    printf("    " RED "[%d] %s exited with status %d\n" DEFAULT, test_num, test.desc, WEXITSTATUS(exec_status));
    result = -1;
  }

  system("rm -f program_name program_name.c");

  return (result);
}

char *modify_string(const char *str)
{
  int len = strlen(str);
  if (len > 0 && str[len - 1] == '\n')
  {
    char *new_str = (char *)malloc(len);
    strncpy(new_str, str, len - 1);
    new_str[len - 1] = '$';
    return new_str;
  }
  else
  {
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
