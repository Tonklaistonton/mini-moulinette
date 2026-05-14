#ifndef EXEC_UTILS_H
#define EXEC_UTILS_H

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stddef.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <unistd.h>

static long	exec_elapsed_ms(struct timeval start, struct timeval now)
{
	return ((now.tv_sec - start.tv_sec) * 1000L
		+ (now.tv_usec - start.tv_usec) / 1000L);
}

static int	capture_command_output(char *const argv[], char *buffer,
	size_t buffer_size, int timeout_seconds, int *wait_status)
{
	int				pipefd[2];
	pid_t			pid;
	size_t			used;
	int				status;
	int				timed_out;
	struct timeval	start;
	struct timeval	now;

	if (buffer == NULL || buffer_size == 0 || argv == NULL || argv[0] == NULL)
		return (-1);
	buffer[0] = '\0';
	used = 0;
	status = 0;
	timed_out = 0;
	if (pipe(pipefd) == -1)
		return (-1);
	pid = fork();
	if (pid == -1)
	{
		close(pipefd[0]);
		close(pipefd[1]);
		return (-1);
	}
	if (pid == 0)
	{
		close(pipefd[0]);
		if (dup2(pipefd[1], STDOUT_FILENO) == -1)
			_exit(127);
		close(pipefd[1]);
		execvp(argv[0], argv);
		_exit(127);
	}
	close(pipefd[1]);
	if (gettimeofday(&start, NULL) == -1)
	{
		close(pipefd[0]);
		kill(pid, SIGKILL);
		waitpid(pid, &status, 0);
		return (-1);
	}
	while (1)
	{
		struct pollfd	pfd;
		int				poll_timeout;
		ssize_t			bytes_read;
		pid_t			waited;

		pfd.fd = pipefd[0];
		pfd.events = POLLIN | POLLHUP;
		pfd.revents = 0;
		poll_timeout = 100;
		if (poll(&pfd, 1, poll_timeout) == -1)
		{
			if (errno == EINTR)
				continue ;
			break ;
		}
		if (pfd.revents & (POLLIN | POLLHUP))
		{
			if (used + 1 < buffer_size)
			{
				bytes_read = read(pipefd[0], buffer + used,
						buffer_size - used - 1);
				if (bytes_read > 0)
					used += (size_t)bytes_read;
				else if (bytes_read == 0)
					break ;
			}
			else
			{
				char	dump[256];

				bytes_read = read(pipefd[0], dump, sizeof(dump));
				if (bytes_read == 0)
					break ;
			}
		}
		waited = waitpid(pid, &status, WNOHANG);
		if (waited == pid)
		{
			if (pfd.revents & POLLHUP)
				break ;
		}
		else if (waited == -1 && errno != ECHILD)
			break ;
		if (gettimeofday(&now, NULL) == -1)
			break ;
		if (exec_elapsed_ms(start, now) >= (long)timeout_seconds * 1000L)
		{
			timed_out = 1;
			kill(pid, SIGTERM);
			sleep(1);
			kill(pid, SIGKILL);
			waitpid(pid, &status, 0);
			break ;
		}
	}
	buffer[used] = '\0';
	close(pipefd[0]);
	if (!timed_out && waitpid(pid, &status, 0) == -1 && errno != ECHILD)
		return (-1);
	if (wait_status != NULL)
		*wait_status = status;
	if (timed_out)
		return (1);
	return (0);
}

#endif
