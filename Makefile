SHELL=/bin/bash

# COLORS #
_RED		=	\e[31m
_GREEN		=	\e[32m
_YELLOW		=	\e[33m
_BLUE		=	\e[34m
_END		=	\e[0m

# COMPILATION #
FLAGS	=	-f elf64

# DIRECTORIES #
DIR_SRCS		=	./srcs/
DIR_INCLUDES	=	./includes/
DIR_OBJS		=	./compiled_srcs/

# FILES #
SRCS			=	famine.s \
					host.s

NAME 		=	Famine

#ifeq ($(BUILD),debug)
#	FLAGS	+=	-DDEBUG
#	DIR_OBJS		=	./debug-compiled_srcs/
#	NAME			=	./debug-Famine
#endif

# COMPILED_SOURCES #
OBJS 		=	$(SRCS:%.s=$(DIR_OBJS)%.o)

## RULES ##
all:			$(NAME)

fsociety:		FLAGS += -DFSOCIETY
fsociety:		all

# VARIABLES RULES #

$(NAME):		$(OBJS_ASM) $(OBJS)
				@printf "\033[2K\r$(_BLUE) All files compiled into '$(DIR_OBJS)'. $(_END)✅\n"
				@ld -o $@ $^
				@printf "\033[2K\r$(_GREEN) Executable '$(NAME)' created. $(_END)✅\n"

# COMPILED_SOURCES RULES #
$(OBJS):		| $(DIR_OBJS)

$(DIR_OBJS)%.o: $(DIR_SRCS)%.s
				@printf "\033[2K\r $(_YELLOW)Compiling $< $(_END)⌛ "
				@nasm $(FLAGS) -I $(DIR_INCLUDES) -o $@ $<

$(DIR_OBJS):
				@mkdir -p $(DIR_OBJS)

# MANDATORY PART #
clean:
				@rm -rf $(DIR_OBJS)
				@printf "\033[2K\r$(_RED) '"$(DIR_OBJS)"' has been deleted. $(_END)🗑️\n"

fclean:			clean
				@rm -rf $(NAME)
				@printf "\033[2K\r$(_RED) '"$(NAME)"' has been deleted. $(_END)🗑️\n"

re:				fclean all

# PHONY #

.PHONY:			all clean fclean re
