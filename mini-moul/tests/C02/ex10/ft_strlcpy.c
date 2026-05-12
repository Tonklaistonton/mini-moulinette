#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../../../ex10/ft_strlcpy.c"
#include "../../../utils/constants.h"

typedef struct s_test
{
    char *desc;
    char dest[40];
    char *src;
    size_t size;
    size_t expected_len;
    char *expected;
} t_test;

int run_tests(t_test *tests, int count);

int main(void)
{
    t_test tests[] = {
        {.desc = "ft_strlcpy(dest[10], \"World!\", 10)",
         .dest = {0},
         .src = "World!",
         .size = 10,
         .expected_len = 6,
         .expected = "World!"},
        {.desc = "ft_strlcpy(dest[10], \"Hello, World!\", 10)",
         .dest = {0},
         .src = "Hello, World!",
         .size = 10,
         .expected_len = 13,
         .expected = "Hello, Wo"},
        {.desc = "ft_strlcpy(dest[5], \"Hello, World!\", 5)",
         .dest = {0},
         .src = "Hello, World!",
         .size = 5,
         .expected_len = 13,
         .expected = "Hell"},
        {.desc = "ft_strlcpy(dest[10], \"\", 5)",
         .dest = {0},
         .src = "",
         .size = 5,
         .expected_len = 0,
         .expected = ""},
        {.desc = "ft_strlcpy(dest[1], \"Hello, World!\", 1)",
         .dest = {0},
         .src = "Hello, World!",
         .size = 1,
         .expected_len = 13,
         .expected = ""},
        {.desc = "ft_strlcpy(dest[5], \"Hello\\0World\", 5)",
         .dest = {0},
         .src = (char[]){'H', 'e', 'l', 'l', 'o', '\0', 'W', 'o', 'r', 'l', 'd', '\0'},
         .size = 5,
         .expected_len = 5,
         .expected = "Hell"},
        {.desc = "ft_strlcpy(dest[0], \"Hello\\0World\", 0)",
         .dest = {0},
         .src = (char[]){'H', 'e', 'l', 'l', 'o', '\0', 'W', 'o', 'r', 'l', 'd', '\0'},
         .size = 0,
         .expected_len = 5,
         .expected = ""},

    };
    int count = sizeof(tests) / sizeof(tests[0]);

    return (run_tests(tests, count));
}

int run_tests(t_test *tests, int count)
{
    int i;
    int error = 0;
    const unsigned char sentinel = 0x5A;

    for (i = 0; i < count; i++)
    {
        size_t j;
        int has_error = 0;
        size_t src_len = strlen(tests[i].src);
        size_t copied_len = 0;
        size_t guard_start = 0;

        if (tests[i].size > 0)
        {
            copied_len = src_len;
            if (copied_len >= tests[i].size)
                copied_len = tests[i].size - 1;
            guard_start = copied_len + 1;
        }
        memset(tests[i].dest, sentinel, sizeof(tests[i].dest));
        size_t result_len = ft_strlcpy(tests[i].dest, tests[i].src, tests[i].size);
        if (result_len != tests[i].expected_len)
        {
            printf("    " RED "[%d] %s Expected return len %zu, got %zu\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected_len, result_len);
            has_error = 1;
        }
        if (copied_len > 0 && memcmp(tests[i].dest, tests[i].expected, copied_len) != 0)
        {
            printf("    " RED "[%d] %s Expected prefix \"%s\"\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected);
            has_error = 1;
        }
        if (tests[i].size > 0 && tests[i].dest[copied_len] != '\0')
        {
            printf("    " RED "[%d] %s Missing null terminator at index %zu\n" DEFAULT, i + 1, tests[i].desc, copied_len);
            has_error = 1;
        }
        for (j = guard_start; j < sizeof(tests[i].dest); j++)
        {
            if ((unsigned char)tests[i].dest[j] != sentinel)
            {
                printf("    " RED "[%d] %s Modified byte past expected write boundary at index %zu\n" DEFAULT, i + 1, tests[i].desc, j);
                has_error = 1;
                break;
            }
        }
        if (has_error)
            error -= 1;
        else
        {
            printf("  " GREEN CHECKMARK GREY " [%d] %s strict null/bounds checks passed\n" DEFAULT, i + 1, tests[i].desc);
        }
    }
    return (error);
}
