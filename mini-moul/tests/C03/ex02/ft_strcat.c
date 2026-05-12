#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../../../ex02/ft_strcat.c"
#include "../../../utils/constants.h"

typedef struct s_test
{
	char	*desc;
	char	*dest;
	char	*src;
	char	*expected;
} t_test;

int run_tests(t_test *tests, int count);

int main(void)
{
	t_test tests[] = {
		{
			.desc = "Append a string to an empty string",
			.dest = "",
			.src = "Hello",
			.expected = "Hello"
		},
		{
			.desc = "Append a string to a non-empty string",
			.dest = "42 ",
			.src = "Network",
			.expected = "42 Network"
		},
		{
			.desc = "Append a string to itself",
			.dest = "Hello",
			.src = "Hello",
			.expected = "HelloHello"
		},
		{
			.desc = "Append an empty string to a non-empty string",
			.dest = "Hello",
			.src = "",
			.expected = "Hello"
		},
		{
			.desc = "Append an empty string to an empty string",
			.dest = "",
			.src = "",
			.expected = ""
		}
	};
	int count = sizeof(tests) / sizeof(tests[0]);

	return (run_tests(tests, count));
}

int	run_tests(t_test *tests, int count)
{
	int				i;
	int				error = 0;
	const unsigned char	sentinel = 0x5A;

	for (i = 0; i < count; i++)
	{
		int		has_error = 0;
		char		dest[100];
		size_t		expected_len = strlen(tests[i].expected);
		char		*result;

		memset(dest, sentinel, sizeof(dest));
		strcpy(dest, tests[i].dest);

		result = ft_strcat(dest, tests[i].src);

		if (result != dest)
		{
			printf("    " RED "[%d] %s Expected return value to be pointer to dest\n" DEFAULT, i + 1, tests[i].desc);
			has_error = 1;
		}
		if (strcmp(dest, tests[i].expected) != 0)
		{
			printf("    " RED "[%d] %s Expected \"%s\", got \"%s\"\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected, dest);
			has_error = 1;
		}
		if (dest[expected_len] != '\0')
		{
			printf("    " RED "[%d] %s Missing null terminator at expected end\n" DEFAULT, i + 1, tests[i].desc);
			has_error = 1;
		}
		if (has_error)
			error -= 1;
		else
			printf("  " GREEN CHECKMARK GREY " [%d] %s Expected \"%s\", got \"%s\"\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected, dest);
	}
	return (error);
}
