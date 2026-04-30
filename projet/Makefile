CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c99
NAME = factorielle

all: $(NAME)

$(NAME): main.c header.h
	$(CC) $(CFLAGS) -o $(NAME) main.c

clean:
	rm -f $(NAME)
