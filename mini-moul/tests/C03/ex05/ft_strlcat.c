#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../../../ex05/ft_strlcat.c"
#include "../../../utils/constants.h"

typedef struct s_test
{
    char *desc;
    char *src;
    char *dest;
    size_t size;
    size_t expected_return;
    char *expected_output;
} t_test;

int run_tests(t_test *tests, int count);

int main(void)
{
    t_test tests[] = {
        {
            .desc = "Concatenate two strings",
            .src = "Born to code",
            .dest = "1337 42",
            .size = 20,
            .expected_return = 19,
            .expected_output = "1337 42Born to code",
        },
        {
            .desc = "Concatenate empty strings",
            .src = "",
            .dest = "",
            .size = 10,
            .expected_return = 0,
            .expected_output = "",
        },
        {
            .desc = "Append to an empty string",
            .src = "hello",
            .dest = "",
            .size = 10,
            .expected_return = 5,
            .expected_output = "hello",
        },
        {
            .desc = "Concatenate with string larger than size",
            .src = "Born to code",
            .dest = "1337 42",
            .size = 7,
            .expected_return = 19,
            .expected_output = "1337 42",
        },
        {
            .desc = "Concatenate same strings with size larger than sum of their lengths",
            .src = "Test",
            .dest = "Test",
            .size = 10,
            .expected_return = 8,
            .expected_output = "TestTest",
        },
        {
            .desc = "Stop at first null in source",
            .src = (char[]){'X', 'Y', '\0', 'Z', '\0'},
            .dest = "ab",
            .size = 10,
            .expected_return = 4,
            .expected_output = "abXY",
        },
        {
            .desc = "Stop at first null in destination",
            .src = "XY",
            .dest = (char[]){'a', 'b', '\0', 'c', '\0'},
            .size = 10,
            .expected_return = 4,
            .expected_output = "abXY",
        },
        {
            .desc = "No write when size is 0",
            .src = "XYZ",
            .dest = "abc",
            .size = 0,
            .expected_return = 3,
            .expected_output = "abc",
        },
    };
    int count = sizeof(tests) / sizeof(tests[0]);

    return run_tests(tests, count);
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
        char dest[100];
        char before[100];
        size_t initial_len = strlen(tests[i].dest);
        size_t expected_len = strlen(tests[i].expected_output);

        memset(dest, sentinel, sizeof(dest));
        memcpy(dest, tests[i].dest, initial_len + 1);
        memcpy(before, dest, sizeof(dest));

        size_t result = ft_strlcat(dest, tests[i].src, tests[i].size);

        if (result != tests[i].expected_return)
        {
            printf("    " RED "[%d] %s Expected return %zu, got %zu\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected_return, result);
            has_error = 1;
        }
        if (strcmp(dest, tests[i].expected_output) != 0)
        {
            printf("    " RED "[%d] %s Expected \"%s\" output \"%s\"\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected_output, dest);
            has_error = 1;
        }
        if (dest[expected_len] != '\0')
        {
            printf("    " RED "[%d] %s Missing null terminator at expected end\n" DEFAULT, i + 1, tests[i].desc);
            has_error = 1;
        }
        if (tests[i].size < sizeof(dest))
        {
            for (j = tests[i].size; j < sizeof(dest); j++)
            {
                if ((unsigned char)dest[j] != (unsigned char)before[j])
                {
                    printf("    " RED "[%d] %s Modified byte past size boundary at index %zu\n" DEFAULT, i + 1, tests[i].desc, j);
                    has_error = 1;
                    break;
                }
            }
        }
        if (has_error)
            error -= 1;
        else
            printf("  " GREEN CHECKMARK GREY " [%d] %s strict null/bounds checks passed\n" DEFAULT, i + 1, tests[i].desc);
    }

    return error;
}
