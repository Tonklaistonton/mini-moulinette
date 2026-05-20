#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#include "../../../../ex05/ft_sqrt.c"
#include "../../../utils/constants.h"

typedef struct s_test
{
    char *desc;
    int n;
    int expected;
} t_test;

int run_tests(t_test *tests, int count);
void run_int_max_warning_test(void);

int main(void)
{
    t_test tests[] = {
        {
            .desc = "Square root of 16",
            .n = 16,
            .expected = 4,
        },
        {
            .desc = "Square root of 0",
            .n = 0,
            .expected = 0,
        },
        {
            .desc = "Square root of 1",
            .n = 1,
            .expected = 1,
        },
        {
            .desc = "Square root of 2",
            .n = 2,
            .expected = 0,
        },
        {
            .desc = "Square root of a negative number",
            .n = -5,
            .expected = 0,
        },
        {
            .desc = "Square root of large perfect square",
            .n = 2147395600,
            .expected = 46340,
        },
    };
    int count = sizeof(tests) / sizeof(tests[0]);

    int error = run_tests(tests, count);
    run_int_max_warning_test();
    return error;
}

int run_tests(t_test *tests, int count)
{
    int i;
    int error = 0;

    for (i = 0; i < count; i++)
    {
        int result = ft_sqrt(tests[i].n);

        if (result != tests[i].expected)
        {
            printf("    " RED "[%d] %s Expected %d, got %d\n", i + 1, tests[i].desc, tests[i].expected, result);
            error -= 1;
        }
        else
        {
            printf("  " GREEN CHECKMARK GREY " [%d] %s Expected %d, got %d\n" DEFAULT, i + 1, tests[i].desc, tests[i].expected, result);
        }
    }

    return error;
}

void run_int_max_warning_test(void)
{
    pid_t   pid;
    int     status;
    int     waited;
    int     ticks;

    pid = fork();
    if (pid == -1)
    {
        printf("  " GREY "[warning] Could not run INT_MAX overflow check\n" DEFAULT);
        return ;
    }
    if (pid == 0)
    {
        if (ft_sqrt(2147483647) == 0)
            _exit(0);
        _exit(2);
    }
    ticks = 0;
    waited = 0;
    while (ticks < 20)
    {
        waited = waitpid(pid, &status, WNOHANG);
        if (waited == pid)
            break ;
        usleep(50000);
        ticks++;
    }
    if (waited != pid)
    {
        kill(pid, SIGKILL);
        waitpid(pid, &status, 0);
        printf("  " GREY "[warning] ft_sqrt(INT_MAX) timed out; likely i * i overflow near 46341\n" DEFAULT);
    }
    else if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
    {
        printf("  " GREY "[warning] ft_sqrt(INT_MAX) should return 0; check for i * i overflow\n" DEFAULT);
    }
    else
    {
        printf("  " GREEN CHECKMARK GREY " [warning] INT_MAX overflow check passed\n" DEFAULT);
    }
}
