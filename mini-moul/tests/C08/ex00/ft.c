#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include "../../../utils/constants.h"

#define FUNCTION_COUNT 5
#define PATH_BUFFER_SIZE 4096

typedef struct
{
  char *name;
  bool exists;
} function_check;

static int build_header_path(char *header_path, size_t size)
{
  char source_dir[PATH_BUFFER_SIZE];
  char *last_slash;
  int written;

  if (strlen(__FILE__) >= sizeof(source_dir))
    return 1;
  strcpy(source_dir, __FILE__);
  last_slash = strrchr(source_dir, '/');
  if (last_slash == NULL)
    strcpy(source_dir, ".");
  else
    *last_slash = '\0';
  written = snprintf(header_path, size, "%s/../../../../ex00/ft.h",
      source_dir);
  return (written < 0 || (size_t)written >= size);
}

int main(void)
{
  function_check functions[FUNCTION_COUNT] = {
      {"ft_putchar", false},
      {"ft_swap", false},
      {"ft_putstr", false},
      {"ft_strlen", false},
      {"ft_strcmp", false},
  };

  char buffer[128];
  char header_path[PATH_BUFFER_SIZE];
  FILE *header_file;

  if (build_header_path(header_path, sizeof(header_path)) != 0)
  {
    fprintf(stderr, "Unable to build ft.h path\n");
    return 1;
  }
  header_file = fopen(header_path, "r");
  if (header_file == NULL)
  {
    perror(header_path);
    return 1;
  }
  while (fgets(buffer, sizeof(buffer), header_file))
  {
    for (int i = 0; i < FUNCTION_COUNT; i++)
    {
      if (strstr(buffer, functions[i].name) != NULL)
      {
        functions[i].exists = true;
      }
    }
  }
  fclose(header_file);

  for (int i = 0; i < FUNCTION_COUNT; i++)
  {
    printf("%s %s\n", functions[i].name, functions[i].exists ? "exists" : "does not exist");
  }

  return 0;
}
