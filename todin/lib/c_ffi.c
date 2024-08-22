#include <poll.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

typedef struct WINDOW_SIZE {
  int lines, cols;
} WINDOW_SIZE;

struct termios original_termios;
struct termios raw;
struct winsize WIN_SIZE;
WINDOW_SIZE GLOBAL_WINDOW_SIZE = {0};
bool RESIZED = false;
struct pollfd *pollfds;

void handle_resize(int);
void enable_no_echo();
void enable_raw_mode();
void disable_raw_mode();
void disable_no_echo();
bool poll_stdin();
WINDOW_SIZE get_win_size();

void init() {
  enable_raw_mode();
  enable_no_echo();
}

void deinit() { tcsetattr(STDIN_FILENO, TCSAFLUSH, &original_termios); }

__attribute__((constructor)) void init_base_termios() {
  tcgetattr(STDIN_FILENO, &original_termios);
  raw = original_termios;
  GLOBAL_WINDOW_SIZE = get_win_size();
  pollfds = calloc(1, sizeof(struct pollfd));
  pollfds[0].fd = 0;
  pollfds[0].events = POLL_IN;
}

void enable_no_echo() {
  raw.c_lflag &= ~(ECHO | ECHONL);
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void enable_raw_mode() {
  raw.c_iflag &= ~(IGNBRK | BRKINT | ICRNL | INLCR | INPCK | ISTRIP | IXON);
  raw.c_lflag &= ~(ICANON | IEXTEN | ISIG);
  raw.c_oflag &= ~(OPOST);
  raw.c_cflag |= (CS8);
  raw.c_cc[VMIN] = 0;
  raw.c_cc[VTIME] = 0;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void disable_raw_mode() {
  raw.c_iflag |= (BRKINT | IGNBRK | ICRNL | INPCK | ISTRIP | IXON);
  raw.c_lflag |= (ICANON | IEXTEN | ISIG);
  raw.c_oflag |= (OPOST);
  raw.c_cflag |= (CS8);
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void disable_no_echo() {
  raw.c_lflag |= ECHO;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

__attribute__((constructor)) void init_resize_handler() {
  struct sigaction sigact;
  sigact.sa_handler = handle_resize;
  sigemptyset(&sigact.sa_mask);
  sigact.sa_flags = 0;
  sigaction(SIGWINCH, &sigact, (struct sigaction *)NULL);
}

WINDOW_SIZE get_win_size() {
  ioctl(0, TIOCGWINSZ, &WIN_SIZE);
  WINDOW_SIZE wz = {.lines = WIN_SIZE.ws_row, .cols = WIN_SIZE.ws_col};
  return wz;
}

void handle_resize(int signal) {
  if (signal == SIGWINCH) {
    GLOBAL_WINDOW_SIZE = get_win_size();
    RESIZED = true;
  }
}

bool has_resized() {
  if (RESIZED) {
    RESIZED = false;
    return true;
  }
  return false;
}

bool poll_stdin() {
  int ret = poll(pollfds, 1, 0);
  if (ret == -1) {
    return false;
  } else if (ret == 0) {
    return false;
  } else {
    if (pollfds[0].revents & POLL_IN) {
      return true;
    }
  }
  return false;
}
